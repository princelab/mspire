#!/usr/bin/ruby

perc_cmd = 'percolator'

require 'optparse'
require 'spec_id/srf'

# percolator_v1.02_32bit_linux -o reverse_meta.sqm normal_NOCYS/meta.sqm reverse_NOCYS/meta.sqm
# percolator_v1.02_32bit_linux -o reverse_cat_meta.sqm -P INV_ reverse_cat_NOCYS/meta.sqm &

file_hash = { 
  :srg => "bioworks.srg",
  :sqg_in => "bioworks.sqg",
  :sqg_decoy => "decoy.sqg",
  :perc_out => "perc.sqg",
  :perc_stdout => "perc.stdout",
  :perc_stderr => "perc.stderr",
  :perc_ext => ".psqt",
}
(default_srg, sqg_in, perc_out, sqg_decoy, perc_stdout, perc_stderr, perc_ext) = file_hash.values_at(:srg, :sqg_in, :perc_out, :sqg_decoy, :perc_stdout, :perc_stderr, :perc_ext)

opt = {}
toclean = []
opts = OptionParser.new do |op|
  op.banner =  "usage: #{File.basename(__FILE__)} -d PATTERN <file>.srf ..."
  op.separator "       #{File.basename(__FILE__)} -d PATTERN <file>.srg"
  op.separator "       #{File.basename(__FILE__)} <normal>.srg <decoy>.srg"
  op.separator ""
  op.separator "  creates necessary meta files in current working directory and"
  op.separator "  runs command '#{perc_cmd}'"
  op.separator ""
  op.separator "  (all in current working directory)"
  op.separator "  1) (if given .srf files) creates file: #{default_srg}"
  op.separator "  2) creates .sqt file for each srf file (placed in dir with srf file)"
  op.separator "  3) creates percolator (meta) input file(s): #{sqg_in}"
  op.separator "                  [and for separate searches: #{sqg_decoy}]"
  op.separator "  4) creates a percolator (meta) output file: #{perc_out}"
  op.separator "  5) runs percolator which creates a  a #{perc_ext} for each .srf file"
  op.separator "  6) captures stdout in #{perc_stdout} and stderr in #{perc_stderr}"
  op.separator ""
  op.separator "  .srg files are text files with full paths to .srf files"
  op.separator "  create with command 'srf_group.rb'"
  op.separator ""
  op.on("-d", "--decoy <pattern>", "decoy pattern, eg.: -d REVERSE_") {|v| opt[:decoy] = v }
  op.on("-c", "--clean", "removes ALL generated files except #{perc_ext}") {|v| opt[:clean] = v }
  op.on("-v", "--verbose", "spits out info") {|v| $VERBOSE = v }
end
opts.parse!

if ARGV.size == 0 or (!opt[:decoy] && (ARGV.size != 2))
  puts opts.to_s
  exit
end

#raise RunTimeError, "command #{perc_cmd} must be callable!" unless `#{perc_cmd}`.match(/Usage/)

files = ARGV.to_a

# create srg file:
srg_files = 
  if files[0] =~ /\.srf$/i
    obj = SRFGroup.new
    obj.filenames = files.to_a
    puts("CREATING: #{default_srg}") if $VERBOSE
    obj.to_srg(default_srg)
    toclean << default_srg
    [default_srg]
  elsif files[0] =~ /\.srg$/i
    files
  else
    abort "files must have proper extensions"
  end

# create the sqt files:
all_sqt_filenames = srg_files.map do |srg_file|
  srf_filenames = SRFGroup.srg_to_paths(srg_file)
  srf_filenames.map do |file|
    new_filename = file.sub(/\.srf$/i, '.sqt')
    puts("CREATING: #{new_filename}") if $VERBOSE
    SRFGroup.new([file], opt['filter']).srfs.first.to_sqt(new_filename)
    toclean << new_filename
    new_filename
  end
end

# create the percolator input file:
all_sqt_filenames.zip(file_hash.values_at(:sqg_in, :sqg_decoy)) do |sqt_filenames,filename|
  puts("CREATING: #{filename}") if $VERBOSE
  File.open(filename, 'w') {|fh| fh.puts(sqt_filenames.join("\n")) }
  toclean << filename 
end

# create the percolator output file:
psqt_filenames = all_sqt_filenames[0].map do |file|
  file.sub(/\.sqt$/, perc_ext)
end

puts("CREATING: #{perc_out}") if $VERBOSE
File.open(perc_out, 'w') {|fh| fh.puts(psqt_filenames.join("\n")) }
toclean << perc_out

# run percolator
to_run = 
  if opt[:decoy]
  "#{perc_cmd} -o #{perc_out} -P #{opt[:decoy]} #{sqg_in} 1>#{perc_stdout} 2>#{perc_stderr}"
  else
  "#{perc_cmd} -o #{perc_out} #{sqg_in} #{sqg_decoy} 1>#{perc_stdout} 2>#{perc_stderr}"
  end

puts("RUNNING: #{to_run}") if $VERBOSE
`#{to_run}`

toclean << perc_stdout
toclean << perc_stderr

if opt[:clean]
  toclean.each do |file|
    puts("REMOVING: #{file}") if $VERBOSE
    File.unlink(file) if File.exist?(file)
  end
end

