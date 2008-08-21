#!/usr/bin/ruby


options_file = "local.cfg"

moving_options_file = false
mv_options_file = ""
if File.exist?(options_file)
  mv_options_file = options_file + ".backup"
  File.rename(options_file, mv_options_file)
  moving_options_file = true
end

filetype = "msmat"
files = ARGV.to_a

base = "Msvis_filename"

if files.size == 0
  puts "msvis.rb file.msmat ..."
  puts "right now only creates a local.cfg file"
  exit
end

File.open(options_file, "w") do |fh|
  fh.print "Msvis_filetype = " + filetype + "\n"
  fh.print "Msvis_num = " + files.size.to_s + "\n"
  cnt = 0
  files.each do |file|
    fh.print( base + cnt.to_s + " = " + "\"#{file}\"" + "\n" )
    cnt += 1
  end
end

#exec "./msvis"

#File.unlink options_file

#if moving_options_file
#  File.rename mv_options_file, options_file
#end

