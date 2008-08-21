#!/usr/bin/ruby

require 'vec'
require 'spec_id'
require 'optparse'
require 'ostruct'
require 'set'


opt = OpenStruct.new
opt.p = ["INV_"]
opt.b = 50
opts = OptionParser.new do |opts|
  opts.banner = "usage: #{File.basename(__FILE__)} [-d -b bins -p prefix[,...]] file ..."
  opts.on_head "\noutputs 'histogram.toplot'\n(then) % plot.rb -w lp --yrange n1: --noenhanced histogram.toplot\n"
  opts.on("-p", "--prefix PREFIX", "(comma sep list) FP protein header prefix (def: #{opt.p})") {|v| opt.p = v.split(',')}
  opts.on("-b", "--bins NUM_BINS", "number of histogram bins (def: #{opt.b})") {|v| opt.b = v.to_i}
  opts.on("-d", "--diff", "plots TP - FP") {|v| opt.b = v.to_i}
end
opts.parse!

if ARGV.size < 1
  puts opts
end

outfile = 'histogram.toplot'
dtype = 'XYData'
outfile_base = 'histogram'
title = 'histogram of protein probabilities'
xaxis = 'probability'
yaxis = 'frequency'
out = File.open(outfile, "w")
[dtype, outfile_base, title, xaxis, yaxis].each do |it|
  out.puts it
end

files = ARGV.to_a
files.each_with_index do |file,i|
  fp = VecD.new; tp = VecD.new
  bio = SpecID.new(file)
  re = /^#{opt.p[i]}/
  bio.prots.each do |prot|
    if prot.reference =~ re
      fp << Math.log10(prot.probability)
    else
      tp << Math.log10(prot.probability)
    end
  end
  if fp.size == 0 then puts "NO FALSE POSITIVES FOUND!  Your prefix is probably wrong ;)" end
  label = file
  t_bin, t_freq = tp.histogram(opt.b)
  f_bin, f_freq = fp.histogram(opt.b)
  out.puts 'TP ' + label
  out.puts t_bin.to_s
  out.puts t_freq.to_s
  out.puts 'FP ' + label
  out.puts f_bin.to_s
  out.puts f_freq.to_s
end

out.close
