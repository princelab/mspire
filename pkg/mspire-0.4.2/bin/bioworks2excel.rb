#!/usr/bin/ruby -w

require 'spec_id/bioworks'

if ARGV.size < 1
  puts "usage: #{File.basename(__FILE__)} bioworks.xml ..."
  exit
end

ARGV.each do |file|
  newfile = file.gsub(".xml", ".txt")
  obj = Bioworks.new(file)
  obj.to_excel(newfile)
end
