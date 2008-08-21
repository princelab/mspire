#!/usr/bin/ruby

require 'rubygems'
require 'ms/msrun'
gem 'axml', '= 0.0.2'

# returns an array containing one or two pairs of [cycle_num, time] that
# represent the lowest and highest cycle numbers coupled to lowest and highest
# time (in seconds) and the lowest and highest associated experiment numbers
def get_cycle_exp_time_triplets(string)
  hash = {}
  cycle_index = nil
  ssplit = string.split(', ')
  ssplit.each_with_index do |piece,i|
    if piece =~ /^Cycle\(s\):/
      cycle_index = i
      break
    end
  end
  cycle_info = ssplit[cycle_index..-1].join(", ")
  #Cycle(s): 663, 675 (Experiment 2), 667 (Experiment 4)
  (header, info) = cycle_info.split(': ')
  cycles = []
  cycle_exp_pairs = []
  info.split('), ').each do |a| 
    (nums, exp_num) = a.split('(')
    nums = nums.split(', ').map {|v| v.to_i }
    exp_num = exp_num.split(' ').last.sub(/\)$/,'').to_i
    nums.each {|v| cycle_exp_pairs << [v, exp_num] }
  end

  min = cycle_exp_pairs.min
  max = cycle_exp_pairs.max

  elution = ssplit.select {|v| v.match(/^Elution:(.*)/) }.first
  times = elution.split(': ').last
  times.sub!(/ min$/,'')
  times = times.split(' to ')
  times.map! do |v| 
    (minutes, minute_decimals) = v.split('.')
    seconds = minutes.to_f * 60
    seconds + ( minute_decimals.to_f * 60 / 100 )
  end

  if max == min
    [[min.first, min.last, times.first]]
  else
    [[min.first, min.last, times.first], [max.first, max.last, times.last]]
  end
end

def get_scan_num(cycle, cycle_time, time_to_scan_num)
  # grossly inefficient, but guaranteed to get right answer!
  below_scan = nil
  time_to_scan_num.each do |scan_time, scan_num| 
    if scan_time < cycle_time 
      below_scan = scan_num
    else
      break  # scan_time > cycle_time
    end
  end
  below_scan
end

#####################################################
# MAIN:
#####################################################

additional_ext = ".with_scan_nums"

if ARGV.size != 2
  puts "usage: #{File.basename(__FILE__)} <file>.pepXML <file>.mzXML"
  puts ""
  puts "uses information from the mzXML file to fix the pepXML file"
  puts "(adds in msms_run_summary: 'base_name' and 'raw_data' attributes;"
  puts " adds scan numbers based on cycle and experiment times)"
  puts ""
  puts "outputs: <file>#{additional_ext}.pepXML"
  exit
end

# get time_to_scan_num for msLevel=1 from the mzXML file
(pepxml, mzxml) = ARGV
mzxml_basename = File.basename(mzxml).sub(/\.mzxml$/i, '')

ext = File.extname(pepxml)
output = pepxml.sub(Regexp.new(Regexp.escape(ext)), additional_ext + ext)

ms = MS::MSRun.new(mzxml, :lazy => :no_spectra)
time_to_scan_num = ms.scans.select {|scan| scan.ms_level == 1 }.map do |scan|
  [scan.time, scan.num]
end

# update spectrum queries based on scan number

root = AXML.parse_file(pepxml)
# fix the basename stuff:
msms_r_summary_n = root.child
atts = msms_r_summary_n.attrs
atts['base_name'] = mzxml_basename
atts['raw_data'] = '.mzXML'

root.child.find("child::spectrum_query").each do |sq|
  triplets = get_cycle_exp_time_triplets(sq['spectrum'])
  triplets.map! do |triplet|
    [get_scan_num(triplet[0], triplet[2], time_to_scan_num), *triplet]
  end
  # [scan_num, cycle, exp, time]
  quad = triplets.first
  first_scan_num = (quad[0] + quad[2] - 1)
  sq.attrs['start_scan'] = first_scan_num.to_s
  sq.attrs['end_scan'] = 
    if triplets.size > 1
      quad = triplets.last
      (quad[0] + quad[2] - 1).to_s
    else
      first_scan_num.to_s
    end
end

xml_header = '<?xml version="1.0" encoding="UTF-8"?>'
File.open(output, 'w') {|out| out.puts(xml_header); out.print root.to_s }

