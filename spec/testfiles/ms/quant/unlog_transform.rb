#!/usr/bin/env ruby

file = ARGV.shift

base = file.chomp(File.extname(file))

File.open(base + '.oneprot.tsv','w') do |out|
  IO.foreach(file) do |line|
    data = line.chomp.split("\t")

    out.puts data.join("\t")
  end
end
