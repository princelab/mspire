#!/usr/bin/ruby -w


require 'roc'
require 'optparse'
require 'generator'

$decoy = false
$base = "precision_vs_numhits"

opts = OptionParser.new do |op|
  op.banner = "usage: #{File.basename(__FILE__)} smriti.csv ..."
  op.separator ""
  op.separator "smriti.csv = (tab delimited) prob, file:seq:charge, T/F"
  op.separator ""
  op.on("--decoy", "'F' indicates this is a decoy") {|v| $decoy = true }
  op.on("-o", "--outfile <filename>", "base outfile name (#{$base})") {|v| $base = v}
end

opts.parse!

if ARGV.size <= 0
  puts opts
  exit
end

files = ARGV.to_a

xys = files.map do |file|
  triplets = IO.readlines(file).reject{|v| v =~ /^#/}.map do |line|
    line.chomp.split("\t")
  end

  # check that they're all OK:
  triplets.each do |trip|
    if trip.size != 3 ; abort "bad triplet" end
  end

  # figure out the ordering (and correct if necessary):
  higher_better = triplets[0][0].to_f > triplets.last[0].to_f

  doublets = triplets.map do |trip|
    value = trip[0].to_f
    value *= -1 if higher_better
    [value, ((trip[2] == 'T') ? true : false)]
  end

  roc = ROC.new

  (tps, fps) = roc.doublets_to_separate(doublets)

  (x, y) = 
    if $decoy
      (numhits, precision) = DecoyROC.new.pred_and_ppv(tps, fps)
      [numhits, precision]
    else
      (numhits, precision) = roc.numhits_and_ppv(doublets)
      [numhits, precision]
    end
  [x,y]

end


## PLOT TO to_plot
File.open( $base + ".to_plot", 'w') do |fh|
  fh.puts "XYData"
  fh.puts $base
  fh.puts "precision vs. num hits"
  fh.puts "num hits"
  fh.puts "precision"
  files.zip(xys) do |file,xy|
    (x,y) = xy
    x.unshift(0)
    y.unshift(1)
    fh.puts file.sub(/\.[^\.]$/,'')
    fh.puts x.join(" ")
    fh.puts y.join(" ")
  end
end

File.open( $base + ".csv", 'w') do |fh|
  columns = []
  files.zip(xys) do |file,xy|
    f = file.sub(/\.[^\.]$/,'')
    (x,y) = xy
    x.unshift("#Hits: #{f}")
    y.unshift("Precision: #{f}")
    columns << x << y
  end
  SyncEnumerator.new(*columns).each do |row|
    fh.puts row.join("\t")
  end
end



