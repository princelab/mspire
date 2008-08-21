#!/usr/bin/ruby -w

require 'gi'

if ARGV.size < 1
  puts "usage: #{File.basename(__FILE__)} <gi> ..."
  puts "calls NCBI for the annotation of the gi"
end


gis = ARGV.to_a.dup

puts( GI.gi2annot(gis).join("\n") )

