#!/usr/bin/ruby

require 'spec_id/srf'
require 'optparse'


opt = {}
opt['db-info'] = false
opt['db-path'] = nil
opt['filter'] = true
opts = OptionParser.new do |op|
  op.banner = "usage: #{File.basename(__FILE__)} [OPTIONS] <file>.srf ..."
  op.separator "outputs: <file>.sqt ..."
  op.separator ""
  op.separator "OPTIONS"
  op.on("-d", "--db-info", "calculates num aa's and md5sum on db") {|v| opt['db-info'] = v }
  op.on("-p", "--db-path <path_to_dir>", "if your database path has changed",
                                         "and you want db-info, then give the",
                                         "path to the new *directory*",
                                         "e.g. /my/new/path") {|v| opt['db-path'] = v }
  op.on("-u", "--db-update", "update the sqt file to reflect --db-path") {|v| opt['db-update'] = v }
  op.on("-n", "--no-filter", "by default, pephit must be within",
                             "peptide_mass_tolerance (defined in params)",
                             "to be displayed.  Turns this off.") {|v| opt['filter'] = false}
  op.on("-r", "--round", "round floating point values reasonably") {|v| opt['round'] = v }
end

opts.parse!

if ARGV.size == 0
  puts opts.to_s 
  exit
end

ARGV.each do |file|
  abort "file #{file} must be named .srf" if file !~ /\.srf$/i
  new_filename = file.sub(/\.srf$/i, '.sqt')
  SRFGroup.new([file], opt['filter']).srfs.first.to_sqt(new_filename, :db_info => opt['db-info'], :new_db_path => opt['db-path'], :update_db_path => opt['db-update'], :round => opt['round'])
end

