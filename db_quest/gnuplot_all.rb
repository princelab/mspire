#!/usr/bin/ruby

require 'optparse'

opts = OptionParser.new do |op|
  op.banner = "usage: #{File.basename(__FILE__)} *.dat"
  op.separator "uses gnuplot commands to plot .dat files"
  op.separator "(uses first commented column for labels)"
  op.separator "(plots last two columns with errorbars (mean, stdev)"
end

if ARGV.size == 0
  puts opts.to_s
  exit
end

filenames = ARGV.to_a

filenames.each do |fn|
  num_cols = nil
  labels = nil
  File.open(fn) do |fh|
    labels = fh.readline.chomp.split("\t")
    labels[0] = labels[0][2..-1]  # remove leading pound key
  end
  mean_index = labels.index('mean')
  stdev_index = labels.index('stdev')

  base = fn.sub(/\.dat/,'')

  
 qfn = "\"#{fn}\""
 dsets = []
 labels.each_with_index do |label, index|
   if index == 0
     # do nothing, x data!
   elsif index == mean_index
     dsets << "using 1:#{index+1} title 'avg vals' with lines"
   elsif index == stdev_index
     dsets << "using 1:#{index}:#{index+1} title 'stdev vals' with errorbars"
   else
     dsets << "using 1:#{index+1} title '#{label}' with lines"
   end
 end
 dsets.map! do |ds|
   [qfn, ds].join(' ')
 end

 plotline = 'plot ' + dsets.reverse.join(", ")

 toex =<<GNUPLOT
#set terminal postscript eps color enhanced
#set output "#{base}.eps"
set terminal png
set output "#{base}.png"
set xlabel "num hits"
set ylabel "precision (TP/TP+FP)"
#set xrange [14000:20000]
#set yrange [0.9:1.0]
#{plotline}
GNUPLOT

  IO.popen( 'gnuplot -persist', 'w') do |io|
    io.puts toex
  end
end
