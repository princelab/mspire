#!/usr/bin/env ruby

require 'gnuplot'
require 'optparse'
require 'ostruct'
require 'set'
require 'array_stats'

require 'mspire/mzml'
require 'mspire/digester'
require 'mspire/mascot/dat'


class Array

  alias_method :sum, :total_sum

  def avg
    sum / array.size
  end

  def weighted_mean(weights_array)
    w_sum = weights_array.sum
    w_prod = 0
    self.each_index {|i| w_prod += self[i] * weights_array[i].to_f}
    w_prod.to_f / w_sum.to_f
  end
end


opt = OpenStruct.new( {
  max_rt_before: 60,
  max_rt_after: 60,
  mz_window: 0.01,
  scan_id_regex: Regexp.new("(.*)"),
  ions_score_cutoff: 15.0,
  # the regex I use:
  #scan_id_regex: Regexp.new("id_([^\\.]+)"),
} )


opts = OptionParser.new do |op|
  op.banner = "usage: #{File.basename(__FILE__)} [OPTS] <mzML> <dat> <accession> ..."
  op.separator "output: <TBD>"
  op.separator ""
  op.separator "options: "
  op.on("--max_rt_before <#{opt.max_rt_before}>", Float, "(sec) max RT to look before") {v| opt.max_rt_before = v }
  op.on("--max_rt_after <#{opt.max_rt_after}>", Float, "(sec) max RT to look after") {v| opt.max_rt_after = v }
  op.on("--mz_window <#{opt.mz_window}>", Float, "(Th) window around m/z value") {|v| opt.mz_window = v }
  op.on("--scan_id_regex <#{opt.scan_id_regex.source}>", "scan") {|v| opt.scan_id_regex = Regexp.new(v) } 
  op.on("--add-filename", "adds the filename to output files") {|v| opt.add_filename = v }
  op.on("--ions-score_cutoff <#{opt.ions_score_cutoff}", Float, "minimum ions score") {|v| opt.ions_score_cutoff = v }
end
opts.parse!

if ARGV.size < 3
  puts opts
  exit
end

(mzml_file, dat_file, *accessions_array) = ARGV

accessions = Set.new(accessions_array)

# block yields the retention time in seconds and stops iteration if the block returns nil/false
def create_chromatogram(mzml, index_enum, mz, mz_window, ms_level=1, &block)
  chromatogram = []
  while index=index_enum.next
    break unless spectrum=mzml[index] 
    next unless ms_level===spectrum.ms_level
    break unless block.call( spectrum.retention_time )
    mzs = spectrum.mzs
    ints = spectrum.intensities
    index = spectrum.find_nearest_index(mz)

    lwin_mz = mz - (mz_window/2.0)
    hwin_mz = mz + (mz_window/2.0)

    
    ints_in_range = []
    index.upto(Float::INFINITY) do |i| 
      if mzs[i] <= hwin_mz
        ints_in_range << ints[i]
      else
        break
      end
    end
    (index-1).downto(0) do |i|
      if mzs[i] >= lwin_mz
        ints_in_range << ints[i]
      else
        break
      end
    end
    if ints_in_range.size > 0
      chromatogram << [spectrum.retention_time, ints_in_range.reduce(:+)]
    end
  end
  chromatogram
end

Pephit = Struct.new(:spectrum_id, :exp_mz, :charge, :seq, :accessions, :var_mods_string, :chromatogram, :mean_mz, :rt, :rt_start, :rt_end, :num_hits, :file_tic, :ions_score)

all_pephits = []
Mspire::Mascot::Dat.open(dat_file) do |dat|
  dat.each_peptide(1) do |pephit|     
    intersecting_accessions = accessions & pephit.protein_hits_info.map(&:accession)
    if intersecting_accessions.size > 0
      query = dat.query(pephit.query_num)
      z = query.charge
      exp_mr = pephit.mr + pephit.delta
      exp_mz = (exp_mr + (z * Mspire::Mass::H_PLUS)) / z
      md=opt.scan_id_regex.match(query.title)
      if md
        spectrum_id = md[1]
      end
      if pephit.ions_score > opt.ions_score_cutoff
        mypephit = Pephit.new(spectrum_id, exp_mz, z, pephit.seq, intersecting_accessions.to_a, pephit.var_mods_string)
        mypephit.ions_score = pephit.ions_score
        all_pephits << mypephit
      end
    end
  end
end

# group all_pephits here, then combine if they aren't outliers
# not a sophisticated algorithm:
# combine everything that is within the windows specified and with same
# sequence, charge, or var_mods_string
pephit_groups = all_pephits.group_by {|pephit| [pephit.seq, pephit.charge, pephit.var_mods_string] }.map do |grouping, pephits|
  # throw out any peptides that are more than the window edges away from the
  # mean of the group
  median_mz = pephits.map(&:exp_mz).median
  same_mz_pephits = pephits.select {|pephit| (pephit.exp_mz - median_mz).abs <= (opt.mz_window / 2.0) }
  mean_mz = same_mz_pephits.map(&:exp_mz).mean
  same_mz_pephits.each {|pephit| pephit.mean_mz = mean_mz }
  same_mz_pephits.size > 0 ? same_mz_pephits : nil
end.compact

puts "Found: #{pephit_groups.size} pephit groupings"
p pephit_groups.first

pephits = Mspire::Mzml.open(mzml_file) do |mzml|

  spec_index = mzml.index_list[:spectrum]

  tic = mzml.map {|spec| spec.fetch_by_acc('MS:1000285').to_f }.reduce(:+)
  
  id_to_index = {}
  spec_index.ids.each_with_index {|id,index| id_to_index[id] = index }

  print "." ; $stdout.flush
  pephit_groups.map do |pephit_group|

    pephit_group.each {|pephit| pephit.rt = mzml[pephit.spectrum_id].retention_time }

    pephit_group.sort_by!(&:rt)

    median_pephit = pephit_group[ pephit_group.size / 2 ]
    median_rt = median_pephit.rt
    valid_pephits = pephit_group.select do |pephit| 
      if pephit.rt <= median_rt
        (median_rt - pephit.rt) <= opt.max_rt_before
      else
        pephit.rt - median_rt <= opt.max_rt_after
      end
    end

    valid_rts = valid_pephits.map(&:rt)
    rep_pephit = median_pephit.dup

    rep_pephit.ions_score = valid_pephits.map(&:ions_score)
    rep_pephit.file_tic = tic

    rep_pephit.rt_start = valid_rts.min - opt.max_rt_before
    rep_pephit.rt_end = valid_rts.max + opt.max_rt_after

    ms1_spec_id = mzml[rep_pephit.spectrum_id].precursors.first.spectrum_id

    index = id_to_index[ms1_spec_id]
    spectrum = mzml[index]

    lo_rt = rep_pephit.rt_start
    hi_rt = rep_pephit.rt_end

    first_chunk = create_chromatogram(mzml, index.downto(0), rep_pephit.mean_mz, opt.mz_window) {|rt| rt >= lo_rt }
    last_chunk = create_chromatogram(mzml, (index+1).upto(Float::INFINITY), rep_pephit.mean_mz, opt.mz_window) {|rt| rt <= hi_rt }

    chromatogram = (first_chunk + last_chunk).sort

    rep_pephit.chromatogram = chromatogram
    rep_pephit
  end
end
puts "finished with mzml"

pephits.each do |pephit|
  fileparts = [:seq, :charge, :var_mods_string].map {|key| pephit.send(key) }
  if opt.add_filename
    fileparts.unshift(dat_file.chomp(File.extname(dat_file)))
  end
  base = fileparts.join('.')
  filename = base + ".tsv"

  puts "writing: #{filename}"
  File.open(filename, 'w') do |out|
    pephit.each_pair do |k,v|
      out.puts "# #{k}: #{v}" unless k.to_sym == :chromatogram
    end
    out.puts
    out.puts "rt(sec)\tintensity"
    pephit.chromatogram.each do |row|
      out.puts row.join("\t")
    end
  end

  xs = pephit.chromatogram.map(&:first)
  ys = pephit.chromatogram.map(&:last)

  Gnuplot.open do |gp|
    Gnuplot::Plot.new( gp ) do |plot|
      plot.title  base
      plot.xlabel "rt(sec)"
      plot.ylabel "intensity"
      plot.terminal "svg"
      plot.output( base + ".svg" )

      plot.data << Gnuplot::DataSet.new( [xs, ys] ) do |ds|
        ds.with = "linespoints"
        ds.notitle
      end
    end
  end
end

