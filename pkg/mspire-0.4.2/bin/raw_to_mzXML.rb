#!/usr/bin/ruby -w

require 'optparse'
require 'ms/converter/mzxml'
require 'fileutils'

progname = File.basename(__FILE__)


opt = {}
opts = OptionParser.new do |op|
  op.banner = "usage: #{progname} [OPTIONS] <file>.RAW ..."
  op.separator ""
  op.on("-p", "--profile", "uses profile output instead of centroid (default)") {|v| opt[:profile] = v}
end

opts.parse!

if ARGV.size == 0
  puts opts
  exit
end

converter = MS::Converter::MzXML.find_mzxml_converter
if converter
  $stderr.puts "using #{converter} to convert files"
else
  puts "cannot find [#{MS::Converter::MzXML::Potential_mzxml_converters.join(', ')}] in the paths:"
  puts ENV['PATH'].split(/[:;]/).join(", ")
  abort
end

files = ARGV.to_a
files.each do |file|
  puts "******************************************"
  puts "Converting: #{file}"
  if converter =~ /readw/
    centroid_or_profile = 'c'
    if opt[:profile] 
      centroid_or_profile = 'p'
    end
    outfile = file.sub(/\.RAW$/i, '.mzXML') 
    cmd = "#{converter} #{file} #{centroid_or_profile} #{outfile}"
    puts "Performing: '#{cmd}'"
    puts `#{cmd}`
  else
    ## t2x only outputs in cwd!
    Dir.chdir(File.dirname(file)) do |dir|
      puts "Performing: '#{cmd}' in #{dir}"
      puts `#{cmd}`
      system "#{converter} #{File.basename(file)}"
    end
  end
  puts "******************************************"
end
