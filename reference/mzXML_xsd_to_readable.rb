#!/usr/bin/ruby -w

ext = ".stcr.stcr.stcr"

if ARGV.size < 1
  puts "usage: #{File.basename(__FILE__)} file ..."
  puts "removes all \\r characters in file(s)" 
  exit
end

puts "Replacing '\\r' chars with '\\n' from:"
ARGV.each do |file|
  puts "#{file}"
  st = File.stat(file)
  tmpfile = file + ext
  if File.exist?(tmpfile) then puts("Tempfile #{tmpfile} already exists! Delete it or move it before running again."); exit end
  File.open(tmpfile, "wb") do |out|
    fh = File.new(file)
    out.print( fh.binmode.read.gsub(/\r/, "\n") )
    fh.close
  end
  File.unlink file
  File.rename(tmpfile, file)
  File.chmod(st.mode, file) 
  File.chown(st.uid, st.gid, file) 
end
