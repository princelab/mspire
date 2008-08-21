#!/usr/bin/ruby -w


if ARGV.size < 2
  puts "usage: #{File.basename(__FILE__)} protxml pepxml"
  puts "Based on some kind of truncated prot xml file, takes a pepxml file"
  puts "and deletes all search hits/peptides that aren't in the prot xml file!"
  exit
end

protxml = ARGV[0]
pepxml = ARGV[1]

hash = {}
File.open(protxml) do |fh|
  while line = fh.gets
    if line =~ /peptide_sequence="(.*?)" charge="(\d)" /
      hash[[$1.dup,$2.dup]] = 1
    end
  end
end

p hash

out = File.open(pepxml + ".small", "w")

in_hit = false
cur_charge = nil
stored_lines = ""
print_it = false
File.open(pepxml) do |fh|
  while line = fh.gets
    if line =~ /<search_result .*? assumed_charge="(\d)".*?>/
      cur_charge = $1.dup
      in_hit = true
    end
    if line =~ /<search_hit .*? peptide="(.*?)"/
      if hash.key?([$1.dup,cur_charge])
        print_it = true
      else
        print_it = false
      end
    end
    if line =~ /<\/search_result>/
      if print_it == true
        stored_lines << line
        out.print stored_lines
      end
      stored_lines = ""
      in_hit == false
    elsif !in_hit
      out.print line
    else
      stored_lines << line
    end
  end


end

out.close
