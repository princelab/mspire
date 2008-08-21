#!/usr/bin/ruby -w

require 'spec_id'
require 'generator'
require 'optparse'
require 'ostruct'
require 'roc'

def file_noext(file)
  file.sub(/#{Regexp.escape(File.extname(file))}$/, '')
end

delimiter = "\t"
def_pre = "SHUFF_"

opt = OpenStruct.new
opt.p = def_pre

jtplot_base = 'class_anal'
jtplot_file = jtplot_base + '.toplot'

OptionParser.new do |op|
  op.on("-p", "--prefix PREFIX", "prefix for false positive proteins") {|v| opt.p = v.split(',') }
  op.on("-j", "--jtplot", "output file '#{jtplot_file}' for jtp plotting program") {|v| opt.j = v }
#  op.on("-e", "--peptides", "runs a full analysis on peptides") {|v| opt.e = v }
  op.on("-a", "--area", "outputs area under the curve") {|v| opt.a = v }
end.parse!

if ARGV.size < 1
  puts "
  usage: #{File.basename(__FILE__)} [options] protein_file.xml ...

  Protein ID classification analysis.  Takes either a bioworks.xml (v3.2 with
  probabilities) or protein_prophet-prot.xml file which has been run with
  decoy proteins.  
  
  Outputs tp's and precision.  
  [The false positive predictive rate (FPPR) is 1 - precision]  
  The two columns will be labeled at the top. 
  (delimited by '\\t') to STDOUT.  To capture to file:
  #{File.basename(__FILE__)} protein_file.xml > out.csv

  OPTIONS:
  <s> = string
  -p  --prefix <s[,s...]>  Prefix(s) by which to determine decoy proteins (default #{def_pre})
  -j  --jtplot        outputs #{jtplot_file} for plotting by plot.rb
                      [% plot.rb -w lp --yrange n0.1:1.1 --noenhanced <file> ]
  -a  --area          outputs area under the curve instead of tps/precision
  
  NOTE: protein prophet files not yet functional!!!
  ABBR:
    TP = True Positives
    FP = False Positives
    Prec = Precision = TP/(TP+FP)
  "
  exit
end

###########################################################
# I DON"T think option -e is functional yet...
###########################################################

files = ARGV.to_a

out = nil
if opt.j
  out = File.open(jtplot_file, "w")
  lines = ['XYData', jtplot_base, "Classification Analysis", "Num Hits", "Precision"]
  lines.each {|l| out.puts l}
end

headings = files.collect do |file|
  %w(TP Precision).collect {|v| v + " (#{file_noext(file)})" }
end

all_arrs = []
files.each_with_index do |file,i|
  sp = SpecID.new(file)
  headers = [file_noext(file)]
  arrs = sp.num_hits_and_ppv_for_prob(opt.p[i])
  
  if opt.a
    (num_hits, prec) = arrs
    roc = ROC.new
    prec_area = roc.area_under_curve(num_hits, prec)
    puts "#{file} (area under curve [num_hits, precision])"
    puts "Prec [#TPPrec = TP/(TP+FP)]:\t#{prec_area}"
  end

  all_arrs.push(*arrs)

  lns = []
  if opt.j
    xs = arrs.shift
    arrs.zip(headers).each do |ar|
      lns << ar[1] << xs.join(" ") << ar[0].join(" ")
    end
    lns.each do |line|
      out.puts line
    end
  end
end


unless opt.a
  puts headings.flatten.join(delimiter)
  SyncEnumerator.new(*all_arrs).each do |row|
    puts row.join(delimiter)
  end
end

out.close if opt.j
