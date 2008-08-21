#!/usr/bin/ruby

require 'optparse'
require 'data_sets'

#######################################################
# MAIN:
#######################################################

opt = {}
opts = OptionParser.new do |op|
  op.banner = "usage: #{File.basename(__FILE__)} filter_validate.yaml ..."
  op.on("-p", "--proteins", "include protein precision") {|v| opt[:proteins] = true }
  op.on("-b", "--by_sequest <attribute>", "attribute = deltacn, ppm, xcorr<n>") {|v| opt[:by_sequest_att] = v }
  op.on("-a", "--average", "average similar types") {|v| opt[:average] = v }
  op.on("--average_all", "average all but decoy") {|v| opt[:average_all] = v }
  op.on("--num_hits", "xaxis is number of hits") {|v| opt[:num_hits] = v }
  op.on("--minus_decoy", "plot each data set less decoy") {|v| opt[:minus_decoy] = v }
end

opts.parse!

if ARGV.size == 0
  puts opts
  exit
end

files = ARGV.to_a
files.each do |filename|
  data_sets = DataSets.load_from_filter_file(filename, opt)

  if opt[:average]
    data_sets.average {|v| v.tp == 'badAA' }
    data_sets.average {|v| v.tp == 'tmm' }
    data_sets.average {|v| v.tp == 'bias' }
  elsif opt[:average_all]
    data_sets.average('average_all') {|v| v.tp != 'decoy' }
  end

  xaxis_label = 
    if opt[:num_hits]
      'num pephits'
    elsif opt[:by_sequest_att] 
      opt[:by_sequest_att]
    else
      'increasing stringency'
    end
  yaxis_label = 'precision (TP/TP+FP)'
  if opt[:minus_decoy]
    yaxis_label << ' [minus decoy precision]'
  end

  basename = filename.sub(/\.yaml$/,'')
  data_sets.print_to_plot(:type => "XYData", :file => basename, :title => "precision plot", :xaxis => xaxis_label, :yaxis => yaxis_label)
end
