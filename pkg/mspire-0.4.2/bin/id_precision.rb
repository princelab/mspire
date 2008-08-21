#!/usr/bin/ruby -w

require 'spec_id'
require 'roc'
require 'generator'
require 'optparse'

################################################
$AREAS_ONLY = false
################################################

opts = OptionParser.new do |op|
  op.banner = "usage: #{File.basename(__FILE__)} prefix bioworks.xml"
  op.separator ""
  op.separator "takes Bioworks 3.2 xml output files (with probabilities)"
  op.separator "rank orders the probabilities and outputs num hits and precision"
  op.separator "Also takes gzipped (xml.gz) files labeled as such"
  op.separator ""
  op.separator "Outputs a comma separated value to STDOUT (.csv)"
  op.separator ""
  op.separator "To capture:"
  op.separator "   #{File.basename(__FILE__)} bioworks.xml > out.csv"
  op.on("-a", "--area", "outputs the area under the curve instead") do |v| $AREAS_ONLY = true end
end

opts.parse!

if ARGV.size < 2
  puts opts
  exit
end

fp_prefix = ARGV[0]
file = ARGV[1]

obj = SpecID.new(file)
re_prefix = /^#{Regexp.escape(fp_prefix)}/o
prc = proc {|it| it.prots.first.reference =~ re_prefix }
#(match, nomatch) = obj.classify(:peps, prc)
obj.peps = obj.pep_prots
(fp, tp) = obj.classify(:peps, prc)


#puts fp.size.to_s
#puts tp.size.to_s
fp_obj = SpecID.new
fp_obj.peps = fp
tp_obj = SpecID.new
tp_obj.peps = tp

two_lists = [tp_obj, fp_obj].map do |obj|
  list = []
  list.push( obj.pep_probs_by_pep_prots )

  list.push( obj.pep_probs_by_bn_seq_charge )
  # These each have a by_min and a by_top10
  list.push(*( obj.pep_probs_by_bn_scan ) )
  list.push(*( obj.pep_probs_by_bn_scan_charge ) )
  list
end


headings = ["PepProts", "SeqCharge", "Scan(TopHit)", "Scan(Top10)", "ScanCharge(TopHit)", "ScanCharge(Top10)"]
csv_headings = []
headings.each do |head|
  csv_headings << head + ": NH"
  csv_headings << head + ": PR"
end

pairs = two_lists[0].zip two_lists[1]

roc = DecoyROC.new
x_y= []
area_under_curve = []
#start_x = []
#end_x = []
pairs.each do |pair|
  #x,y = roc.pred_and_tps_and_ppv(pair[0], pair[1])
  (num_hits, tps, ppv) = roc.pred_and_tps_and_ppv(pair[0], pair[1])
  x = num_hits
  y = ppv
  if $AREAS_ONLY
    x.unshift 0
    y.unshift 1.0
    area_under_curve << roc.area_under_curve(x,y)
    #start_x << x.first
    #end_x << x.last
  else
    x_y.push(x, y)   # <- normal output
  end
end

if $AREAS_ONLY
  headings.unshift "Filename"
  puts headings.join(" ")
  area_under_curve.unshift file
  puts area_under_curve.join(" ")
  #puts start_x.join(" ")
  #puts end_x.join(" ")
  exit           ### <--------------  ABORT HERE
end


# X axis is the number of peptides id# (i.e., # of peps in TP db)
# Y axis is the precision = TP/(TP+FP)

puts "#  NH = number of hits"
puts "#  TP = true positives"
puts "#  FP = false positives"
puts "#  PR = precision = TP/(TP+FP)"
puts csv_headings.join(",")

SyncEnumerator.new(*x_y).each do |row|
  #items_as_string = row.collect do |item|
  #  sprintf("%.18f", item)
  #end

  ## THIS IS THE NORMAL OUTPUT:
  puts row.join(", ")
   

  #puts items_as_string.join(", ")
end

=begin

files = ARGV.to_a

two_lists = files.collect do |file|
  obj = Bioworks.new(file)
  list = []
  list.push( obj.pep_probs_by_pep_prots )
  list.push( obj.pep_probs_by_seq_charge )
  # These each have a by_min and a by_top10
  list.push(*( obj.pep_probs_by_scan ) )
  list.push(*( obj.pep_probs_by_scan_charge ) )
  list
end


headings = ["PepProts: TP", "PepProts: PR", "SeqCharge: TP", "SeqCharge: PR",
  "Scan(TopHit): TP", "Scan(TopHit): PR", "Scan(Top10): TP", "Scan(Top10): PR",
  "ScanCharge(TopHit): TP", "ScanCharge(TopHit): PR",
  "ScanCharge(Top10): TP", "ScanCharge(Top10): PR"]

pairs = two_lists[0].zip two_lists[1]

roc = ROC.new
x_y= []
pairs.each do |pair|
  x,y = roc.tps_and_precision(pair[0], pair[1])
  x_y.push(x, y)
end

# X axis is the number of peptides id# (i.e., # of peps in TP db)
# Y axis is the precision = TP/(TP+FP)

puts "#  TP = true positives"
puts "#  FP = false positives"
puts "#  PR = precision = TP/(TP+FP)"
puts headings.join(",")

SyncEnumerator.new(*x_y).each do |row|
  #items_as_string = row.collect do |item|
  #  sprintf("%.18f", item)
  #end
  puts row.join(", ")
  #puts items_as_string.join(", ")
end

=end

