#!/usr/bin/ruby

require 'optparse'
require 'spec_id/sqt'

$OUTFILE = 'bioworks.sqg'

opts = OptionParser.new do |op|
  op.banner = "usage: #{File.basename(__FILE__)} <file1>.sqt <file2>.sqt ..."
  op.separator "outputs: 'bioworks.sqg'"
  op.separator ""
  op.separator "    A '.sqg' file is an ascii text file with a list"
  op.separator "    of the sqt files (full path names) in that group."
  op.separator ""
  op.on('-o', '--output <filename>', 'a different output name') {|v| $OUTFILE }
end

if ARGV.size == 0
  puts opts
  exit
end

obj = SQTGroup.new
obj.filenames = ARGV.to_a
obj.to_sqg($OUTFILE)

