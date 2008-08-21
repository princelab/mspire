#!/usr/bin/ruby -w

require 'data_sets'

if ARGV.size == 0
  puts "usage: #{File.basename(__FILE__)} <file>.yaml"
  puts "spits out a .to_plot file"
  exit
end

files = ARGV.to_a

files.each do |file|

  dsets = DataSets.background_datasets_from_prob_file(file)

  # remove the probability one
  dsets.reject! {|v| (v.tp == 'prob') or (v.tp == 'decoy') or (v.tp == 'qval')}

  # use only one of the cys ones:
  #dsets.single_badAA!('badAA (dig & exp)')

  base = file.sub(/\.yaml$/, '')

  dsets.print_to_plot(:type => 'XYData', :file => base, :title => 'Probability Based Background Calculation', :xaxis => 'hit (ordered by probability and others)', :yaxis => 'false IDs / total IDs')

end
