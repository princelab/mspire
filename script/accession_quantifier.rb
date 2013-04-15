#!/usr/bin/env ruby

require 'optparse'
require 'ostruct'
require 'set'

require 'mspire/mzml'
require 'mspire/digester'
require 'mspire/mascot/dat'


class Array

  def sum
    inject( nil ) { |sum,x| sum ? sum + x.to_f : x.to_f }
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
  scan_id_regex: Regexp.new("id_([^\\.]+)"),
} )

opts = OptionParser.new do |op|
  op.banner = "usage: #{File.basename(__FILE__)} [OPTS] <mzML> <dat> <accession> ..."
  op.separator "output: <TBD>"
  op.separator ""
  op.separator "options: "
  op.on("--max_rt_before <60>", Float, "(sec) max RT to look before") {v| opt.max_rt_before = v }
  op.on("--max_rt_after <60>", Float, "(sec) max RT to look after") {v| opt.max_rt_after = v }
  op.on("--mz_window <#{opt.mz_window}>", Float, "(Th) window around m/z value") {|v| opt.mz_window = v }
  op.on("--enzyme <String>", "provide enzyme name if can't match") {|v| opt.enzyme = v }
  op.on("--scan_id_regex <#{opt.scan_id_regex.source}>", "scan") {|v| opt.scan_id_regex = Regexp.new(v) } 
end

if ARGV.size < 4
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

Pephit = Struct.new(:spectrum_id, :exp_mz, :charge, :seq, :accessions, :var_mods_string)

pephits = []
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
      pephits << Pephit.new(spectrum_id, exp_mz, z, pephit.seq, intersecting_accessions.to_a, pephit.var_mods_string)
    end
  end
end


Mspire::Mzml.open(mzml_file) do |mzml|
  spec_index = mzml.index_list[:spectrum]

  tic = mzml.map {|spec| spec.fetch_by_acc('MS:1000285').to_f }.reduce(:+)
  puts "#{mzml_file} TIC: #{tic}"
  
  divisor = tic.to_f/1e7

  id_to_index = {}
  spec_index.ids.each_with_index {|id,index| id_to_index[id] = index }

  pephits.each do |pephit|

    ms1_spec_id = mzml[pephit.spectrum_id].precursors.first.spectrum_id
    index = id_to_index[ms1_spec_id]
    spectrum = mzml[index]

    orig_rt = spectrum.retention_time
    lo_rt = orig_rt - opt.max_rt_before
    hi_rt = orig_rt + opt.max_rt_after

    first_chunk = create_chromatogram(mzml, index.downto(0), pephit.exp_mz, opt.mz_window) {|rt| rt >= lo_rt }
    last_chunk = create_chromatogram(mzml, (index+1).upto(Float::INFINITY), pephit.exp_mz, opt.mz_window) {|rt| rt <= hi_rt }

    chromatogram = (first_chunk + last_chunk).sort
    chromatogram.each {|pair| pair[1] /= divisor }

    filename = [pephit.seq, pephit.charge].join(".") + ".tsv"
    puts "writing: #{filename}"
    File.open(filename, 'w') do |out|
      pephit.each_pair do |k,v|
        out.puts "# #{k}: #{v}"
      end
      out.puts
      out.puts "rt(sec)\tnorm_intensity"
      chromatogram.each do |row|
        out.puts row.join("\t")
      end
    end
  end
end



