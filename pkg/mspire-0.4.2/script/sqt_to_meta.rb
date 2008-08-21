#!/usr/bin/ruby -s

require 'optparse'

$outfile = 'meta.sqm'
opts = OptionParser.new do |op|
  op.banner = "usage: #{File.basename(__FILE__)} <file>.sqt ..."
  op.separator "outputs meta.sqm (a sqt meta file)"
  op.on("-o", "--outfile <file>", "currently: #{$outfile}") {|v| $outfile = v}
end

opts.parse!

if ARGV.size == 0
  puts opts.to_s
  exit
end

File.open($outfile, 'w') do |out|
  ARGV.each do |file|
    out.puts File.expand_path(file)
  end
end

