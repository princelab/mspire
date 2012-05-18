#!/usr/bin/env ruby

require 'trollop'
require 'mspire/mzml'
require 'mspire/peaklist'
require 'mspire/tagged_peak'
require 'mspire/peak'

def putsv(*args)
  if $VERBOSE
    puts(*args)
  end
end

DEFAULT_OUTFILE = "quant_compare.tsv"

DEFAULTS = { 
  :bin_width => Mspire::PeakList::DEFAULT_MERGE[:bin_width], 
  :bin_unit => Mspire::PeakList::DEFAULT_MERGE[:bin_unit],
  :split => Mspire::PeakList::DEFAULT_MERGE[:split],
  :round_mz => 6,
  :round_intensity => 6,
  :mz_prefix => "mz"
}

parser = Trollop::Parser.new do
  banner "usage: #{File.basename(__FILE__)} <file>.mzML ..."
  banner "output: #{DEFAULT_OUTFILE}"
  banner ""
  opt :outfile, "write results to this file", :default => DEFAULT_OUTFILE
  opt :bin_width, "width of the bins for merging", :default => DEFAULTS[:bin_width]
  opt :bin_unit, "units for binning (ppm or amu)", :default => DEFAULTS[:bin_unit].to_s
  opt :split, "share|greedy_y|zero method used to distinguish peaks", :default => DEFAULTS[:split].to_s
  opt :sample_ids, "a yml file pointing basename to id", :type => :string
  opt :mz_prefix, "use this prefix for mz values", :default => DEFAULTS[:mz_prefix]
  opt :round_mz, "round the final m/z values to this place", :default => DEFAULTS[:round_mz]
  opt :round_intensity, "round the final int values to this place", :default => DEFAULTS[:round_intensity]
  opt :simple_calibrate, "adjust the m/z values by that amount", :default => 0.0
  opt :verbose, "talk about it"
end

opts = parser.parse(ARGV)
opts[:bin_unit] = opts[:bin_unit].to_sym
opts[:split] = opts[:split].to_sym
$VERBOSE = opts.delete(:verbose)

if ARGV.size == 0
  parser.educate 
  exit
end


files = ARGV.dup

peaklist = Mspire::PeakList.new

if opts[:sample_ids]
  basename_to_sample_id = YAML.load_file(opts[:sample_ids]) 
end

sample_ids = files.map do |filename|
  basename = filename.chomp(File.extname(filename))
  basename_to_sample_id ? basename_to_sample_id[basename] : basename
end

peaklists = files.map do |filename|
  putsv "processing: #{filename}"
  bunch_of_peaks = []
  Mspire::Mzml.open(filename) do |mzml|
    mzml.each_with_index do |spec,i|
      if spec.ms_level == 1
        bunch_of_peaks.push(*spec.peaks)
      end
    end
  end
  peaklist.sort_by!(&:x)
  peaklist
end

putsv "merging peaks"
share_method = :greedy_y
#share_method = :share

ar_of_doublets = Mspire::PeakList.merge_and_deconvolve(peaklists, opts.merge( {:split => share_method, :return_data => true} ))

File.open(opts[:outfile],'w') do |out|

  header = ["mzs", *sample_ids]
  out.puts header.join("\t")

  ar_of_doublets.each do |mz, ar_of_signals|

    row = [opts[:mz_prefix] + (mz + opts[:simple_calibrate]).round(opts[:round_mz]).to_s, *ar_of_signals.map {|signal| signal.round(opts[:round_intensity]) }]
    out.puts row.join("\t")
  end
end

