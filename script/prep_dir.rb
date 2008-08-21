#!/usr/bin/ruby -w


## Assumes the same base
module Kernel

  @@remove_raw = [/flush/, /equil/, /To_sequest/, /to_sequest/, /TempSequence/]
  @@seqext = '.sequest.zip'
  @@rawext = ['.RAW.zip', '.raw.zip']

## gets the basename of a file like this filename.RAW.zip or filename.raw.zip
  def get_basename(zip_file)
    basename = ""
    try1 = File.basename(zip_file, @@rawext[0])
    try2 = File.basename(zip_file, @@rawext[1])

    if try1.size < try2.size
      basename = try1 
    elsif try1.size > try2.size
      basename = try2 
    else #they are equal
      puts "something wrong at the basename"
      exit(1)
    end
    basename
  end
  def remove_extra_raw
    Dir.new(Dir.getwd).each do |test|
      @@remove_raw.each do |try|
        if test =~ try
          puts "removing " + test
          File.unlink test
        end
      end
    end
  end

  def raw2mzXML
    system "raw2mzXML.pl *.RAW"
  end

  def get_sequest_params(seqfile)
    unless File.exist?(seqfile)
      puts "couldn't find #{seqfile}"
      exit
    end
    basename = get_seq_basename(seqfile)
    extracted = basename + "/sequest.params"
    system "unzip #{seqzip} #{extracted}"
    return extracted
  end

  def get_seq_basename(file)
    File.basename(file, @@seqext)
  end

end

if ARGV.size < 1
  puts "usage: #{File.basename(__FILE__)} file.raw.zip"
  puts "This is specific to Peng's data to prepare it for OPD"
  exit
end

rawfiles = []
seqfiles = []
ARGV.each do |try|
  if try =~ /\.raw\.zip/
    rawfiles.push(try)
  elsif try =~ /\.sequest\.zip/
    seqfiles.push(try)
  else
    puts "skipping " + try
  end
end


## depends on them being alphebetical
(0..(rawfiles.size)).each do |cnt|
  rawfile = rawfiles[cnt]
  seqfile = seqfiles[cnt]
  break unless rawfile
  raw_basename = get_basename(rawfile)
  system("unzip #{rawfile}")
  puts "Basename: " + raw_basename
  current_dir = Dir.getwd
  unless Dir.chdir(raw_basename)
    puts "can't change to #{raw_basename}"
    exit
  end
  remove_extra_raw
  raw2mzXML
  system("mkdir raw")
  system("mkdir mzxml")
  system('mv *.RAW raw/')
  system('mv *.mzXML mzxml/')
  Dir.chdir(current_dir)
  rawzip = raw_basename + '.raw.zip'
  mzxmlzip = raw_basename + '.mzxml.zip'
  system("zip -r #{rawzip} #{raw_basename}/raw/*")
  system("zip -r #{mzxmlzip} #{raw_basename}/mzxml/*")
  system("mv #{rawzip} #{raw_basename}")
  system("mv #{mzxmlzip} #{raw_basename}")
  Dir.chdir(raw_basename)
  if (Dir.glob("*.zip").size == 2)
    system("rm -rf raw") 
    system("rm -rf mzxml") 
  end
  Dir.chdir current_dir

  ## get the sequest.params file:
  extracted = get_sequest_params(seqfile)
  system("mv #{extracted} #{raw_basename}")

  ## move the sequest file in
  system("chmod 664 #{seqfile}")
  system("mv #{seqfile} #{raw_basename}")

end


