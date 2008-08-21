#!/usr/bin/ruby

require 'ms/msrun'
require 'optparse'
require 'ostruct'
require 'lmat'


# defaults:
opt = {}
opt[:baseline] = 0.0
opt[:newext] = ".lmat"
opt[:inc_mz] = 1.0

# get options:
opts = OptionParser.new do |op|
  op.banner = "usage: #{File.basename(__FILE__)} [options] <msfile> ..."
  op.separator "input: .mzdata or .mzXML (versions 1.x and 2.x)"
  op.separator ""
  op.separator "(sums m/z values that round to the same bin)"
  op.separator ""
  op.on("--mz_inc N", Float, "m/z increment (def: 1.0)") {|n| opt[:mz_inc] = n.to_f}
  op.on("--mz_start N", Float, "m/z start (def: start of 1st full scan)") {|n| opt[:start_mz] = n.to_f}
  op.on("--mz_end N", Float, "m/z end (def: end of 1st full scan)") {|n| opt[:end_mz] = n.to_f}
  op.on("--baseline N", Float, "value for missing indices (def: #{opt[:baseline]})") {|n| opt[:baseline] = n.to_f}
  op.on("--ascii", "generates an lmata file instead") {opt[:ascii] = true}
  op.on("-v", "--verbose") {$VERBOSE = true}
end
opts.parse!

if ARGV.size < 1 
  puts opts
end

ARGV.each do |file|
  msrun = MS::MSRun.new(file)
  mslevel = 1
  (start_mz, end_mz) = msrun.start_and_end_mz(mslevel)
  (times, spectra) = msrun.times_and_spectra(mslevel)
  args = {
    :start_mz => start_mz,
    :end_mz => end_mz,

    :start_tm => times.first,
    :end_tm => times.last,
    :inc_tm => nil,
  }
  args.merge!(opt)
  lmat = LMat.new.from_times_and_spectra(times, spectra, args)
  ext = File.extname(file)
  outfile = file.sub(/#{Regexp.escape(ext)}$/, opt[:newext])
  if args[:ascii]
    outfile << "a"
    lmat.print(outfile)
  else
    lmat.write(outfile)
  end
  puts("OUTPUT: #{outfile}") if $VERBOSE
end








