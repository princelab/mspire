#!/usr/bin/ruby -w

if ARGV.size == 0
  puts "usage: #{File.basename(__FILE__)} *.to_plot"
  puts "custom modification in prep for printing"
  exit
end

stock_labels = ['badAA (dig & est)', 'tmm (tpred: >=1)', 'tmm (tpred: >=2)', 'tmm (phob: >=1)', 'tmm (phob: >=2)', 'bias (mrna)', 'bias (prot)']

ARGV.each do |file|
  labels = stock_labels.dup
  File.open("tmp.tmp", "w") do |out|
    lines = IO.readlines(file)
    out.print lines[0,5]
    out.puts labels.shift 
    out.print lines[6,2]
    lines[11..-1].each_with_index do |line,i|
      if i % 3 == 0
        out.puts labels.shift
      else
        out.print line
      end
    end
  end
  system "mv tmp.tmp #{file}"
end
