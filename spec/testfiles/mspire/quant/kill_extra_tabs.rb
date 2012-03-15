#!/usr/bin/env ruby

file = ARGV.shift

base = file.chomp(File.extname(file))

File.open(base + '.killedextratabs.tsv','w') do |out|
  IO.foreach(file) do |line|
    data = line.chomp.split("\t")
    data = data[0,data.rindex {|v| !v.nil? }+1]
    out.puts data.join("\t")
  end
end
