#!/usr/bin/ruby


require 'optparse'
require 'spec_id/srf'

$OUTFILE = 'bioworks.srg'

opts = OptionParser.new do |op|
  op.banner = "usage: #{File.basename(__FILE__)} <file1>.srf <file2>.srf ..."
  op.separator "outputs: 'bioworks.srg'"
  op.separator ""
  op.separator "    A '.srg' file is an ascii text file with a list"
  op.separator "    of the srf files (full path names) in that group."
  op.separator ""
  op.on('-o', '--output <filename>', 'a different output name') {|v| $OUTFILE }
end

if ARGV.size == 0
  puts opts
  exit
end

obj = SRFGroup.new
obj.filenames = ARGV.to_a
obj.to_srg($OUTFILE)

