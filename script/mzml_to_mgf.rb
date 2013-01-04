#!/usr/bin/env ruby

require 'mspire/mzml'
require 'optparse'

opt = {
  filter_zero_intensity: true,
  retention_times: true,
}
opts = OptionParser.new do |op|
  op.banner = "usage: #{File.basename($0)} <file>.mzML ..."
  op.separator "outputs: <file>.mgf"
  #op.on("--no-filter-zeros", "won't remove values with zero intensity") {|v| opt[:filter_zero_intensity] = false }
  # the default is set in ms/msrun/search.rb -> set_opts
  op.on("--no-retention-times", "won't include RT even if available") {|v| opt[:retention_times] = false }
end

opts.parse!

if ARGV.size == 0
  puts opts
  exit
end

ARGV.each do |file|
  if File.exist?(file)
    Mspire::Mzml.foreach(file).with_index do |spectrum,i|
      next unless spectrum.ms_level > 1
      puts "BEGIN IONS"
      # id, spectrumid, 
      rt = spectrum.retention_time
      title = [i, "id_#{spectrum.id}", "rt_#{rt.round}"].join('.')
      puts "TITLE=#{title}"
      puts "RTINSECONDS=#{rt}" if opt[:retention_times]
      puts "PEPMASS=#{spectrum.precursor_mz}"
      puts "CHARGE=#{spectrum.precursor_charge}+"
      spectrum.each do |mz,int|
        puts [mz, int].join(" ")
      end
      puts "END IONS"
      puts ""
    end
  else
    puts "missing file: #{file} [skipping]"
  end
end
