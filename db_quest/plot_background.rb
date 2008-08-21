#!/usr/bin/ruby

require 'data_sets'
require 'gnuplot'

if ARGV.size == 0
  puts "usage: #{File.basename(__FILE__)} filter_validate.yaml ..."
  puts "creates .to_plot files for each .yaml file"
  exit
end

ARGV.each do |filename|

  dsets = DataSets.load_backgrounds_from_filter_file(filename)

  #dsets.single_badAA!('badAA (dig & exp)')
  dsets.reject! {|v| v.tp == 'decoy' }
  
  basename = filename.sub(/\.yaml/, '')

  dsets.print_to_plot(:type => 'XYData', :file => basename, :title => "Background Determination #{basename}", :xlabel => "filtering stringency (arbitrary units)", :ylabel => "background fraction")
end


