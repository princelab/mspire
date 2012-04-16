#!/usr/bin/env ruby

require 'trollop'
require 'mspire/mzml'
require 'mspire/peak_list'
require 'mspire/peak'

DEFAULT_OUTFILE = "quant_compare.tsv"

DEFAULTS = { 
  :bin_width => Mspire::PeakList::DEFAULT_MERGE[:bin_width], 
  :bin_unit => Mspire::PeakList::DEFAULT_MERGE[:bin_unit],
}

parser = Trollop::Parser.new do
  banner "usage: #{File.basename(__FILE__)} <file>.mzML ..."
  banner "output: #{DEFAULT_OUTFILE}"
  banner ""
  opt :outfile, "write results to this file", :default => DEFAULT_OUTFILE
  opt :bin_width, "width of the bins for merging", :default => DEFAULTS[:bin_width]
  opt :bin_unit, "units for binning (ppm or amu)", :default => DEFAULTS[:bin_unit].to_s
  opt :sample_ids, "a yml file pointing basename to id", :type => :string
end

opts = parser.parse(ARGV)
opts[:bin_unit] = opts[:bin_unit].to_sym

if ARGV.size == 0
  parser.educate 
  exit
end

class TracedPeak < Array
  # the m/z or x value
  alias_method :x, :first
  # the intensity or y value
  alias_method :y, :last

  def initialize(data, sample_id)
    self[0] = data.first
    self[1] = sample_id
    self[2] = data.last
  end

  def sample_id
    self[1]
  end

  def sample_id=(val)
    self[1] = val
  end
end

files = ARGV.dup

peaklist = Mspire::PeakList.new

if opts[:sample_ids]
  basename_to_sample_id = YAML.load_file(opts[:sample_ids]) 
end

index_to_sample_id = {}
sample_ids = files.each_with_index.map do |filename,index|
  basename = filename.chomp(File.extname(filename))
  sample_id = basename_to_sample_id ? basename_to_sample_id[basename] : basename
  puts "processing: #{filename}"
  Mspire::Mzml.open(filename) do |mzml|
    mzml.each_with_index do |spec,i|
      if spec.ms_level == 1
        peaks = spec.peaks
        #p peaks.size
        peaks.each do |peak|
          tp = TracedPeak.new(peak, index)
          peaklist << tp
        end
      end
    end
  end
  index_to_sample_id[index] = sample_id
  sample_id
end

puts "gathered #{peaklist.size} peaks!"

puts "sorting all peaks"
peaklist.sort! 

puts "merging peaks"
#share_method = :greedy_y
share_method = :share

$VERBOSE = true
data = Mspire::PeakList.merge([peaklist], opts.merge( {:only_data => true, :split => share_method} ))
p data.size
p data.first.size

File.open(opts[:outfile],'w') do |out|

  header = ["mzs", *sample_ids]
  out.puts header.join("\t")

  data.each do |bucket_of_peaks|
    signal_by_sample_index = Hash.new {|h,k| h[k] = 0.0 }
    mz = weighted_mz
    row = [mz.round(6), *sample_ids.each_with_index.map {|id,index| signal_by_sample_index[index] }]
    out.puts row.join("\t")
  end
end


