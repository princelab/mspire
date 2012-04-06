#!/usr/bin/env ruby

require 'trollop'
require 'mspire/mzml/data_array'

parser = Trollop::Parser.new do
  banner "usage: #{File.basename(__FILE__)} [OPTIONS] <base64> ..."
  banner "output: space separated data, one line per base64 string"
  banner ""
  opt :type, "kind of data (float32|float64|int8|int16|int32|int64)", :default => 'float64'
  opt :not_compressed, "zlib compression was *not* used"
end

begin
  opts = parser.parse(ARGV)
rescue help=Trollop::HelpNeeded 
end

if help || ARGV.size == 0
  parser.educate && exit
end

type = opts[:type].to_sym
compressed = !opts[:not_compressed]

ARGV.each do |base64|
  puts Mspire::Mzml::DataArray.from_binary(base64, type, compressed).join(" ")
end






