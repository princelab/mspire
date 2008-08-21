#!/usr/bin/ruby -w

require 'data_sets'

if ARGV.size == 0
  puts "usage: #{File.basename(__FILE__)} *.yaml ..."
  puts "makes a csv (tab delimited) file of important variables"
  exit
end

ARGV.each do |file|
  DataSets.file_to_csv(file)
end
