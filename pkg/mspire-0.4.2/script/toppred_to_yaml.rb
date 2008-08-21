#!/usr/bin/ruby -w


require 'optparse'

opt = {}
opt[:probability] = 1.0
opts = OptionParser.new do |op|
  op.banner = "USAGE: #{File.basename(__FILE__)} toppred.out"
  op.separator "Outputs toppred.yaml"
  op.separator "takes the highest probability structure"
  op.separator "for best structures of equal probability, takes first given"
  op.separator "Each line contains:"
  op.separator "<identifier>: String :"
  op.separator "                      num_found: Int"
  op.separator "                      num_certain_transmembrane_segments: Int"
  op.separator "                      num_putative_transmembrane_segments: Int"
  op.separator "                      best_structure_probability: Float"
  op.separator "                      transmembrane_segments:"
  op.separator "                        - probability: Float"
  op.separator "                          start: Int"
  op.separator "                          stop: Int"
  op.separator "                          aaseq: String"
  op.separator ""
  op.separator "OPTIONS:"
  op.on("-p", "--probability", Float, "min structure prob threshold (default #{opt[:probability]})") {|v| opt[:probability] = v}
end

opts.parse!


if ARGV.size == 0
  puts opts
  exit
end

file = ARGV.shift

File.open(file) do |fh|
  hash = Transmem.read_toppred(fh)
end

puts hash.to_yaml




