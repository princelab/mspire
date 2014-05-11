#!/usr/bin/env ruby

require 'mspire/mzml'
require 'optparse'


# returns '3+' for 3 or '2-' for -2
def mascot_charge(val)
  "#{val}#{val > 0 ? '+' : '-'}"
end

opt = {
  filter_zero_intensity: true,
  retention_times: true,
}
opts = OptionParser.new do |op|
  op.banner = "usage: #{File.basename($0)} <file>.mzML ..."
  op.separator "outputs: <file>.mgf"
  op.on("--no-filter-zeros", "won't remove values with zero intensity") {|v| opt[:filter_zero_intensity] = false }
  # the default is set in ms/msrun/search.rb -> set_opts
  op.on("--no-retention-times", "won't include RT even if available") {|v| opt[:retention_times] = false }
end

opts.parse!

if ARGV.size == 0
  puts opts
  exit
end

filter_zeros = opt[:filter_zero_intensity]

ARGV.each do |file|
  basename = file.chomp(File.extname(file))
  outfile = basename + ".mgf"

  File.open(outfile, 'w') do |out|
    Mspire::Mzml.foreach(file).with_index do |spectrum,i|
      next unless spectrum.ms_level > 1 && spectrum.mzs.size > 0
      out.puts "BEGIN IONS"
      # id, spectrumid, 
      rt = spectrum.retention_time
      title_ar = [i, "id_#{spectrum.id}"]
      title_ar.push("rt_#{rt.round}") if opt[:retention_times]
      title = title_ar.join('.')
      out.puts "TITLE=#{title}"
      out.puts "RTINSECONDS=#{rt}" if opt[:retention_times]
      out.puts "PEPMASS=#{spectrum.precursor_mz}"
      if z=spectrum.precursor_charge
        out.puts "CHARGE=#{mascot_charge(z)}"
      end

      spectrum.each do |mz,int|
        unless filter_zeros && (int==0.0)
          out.puts([mz, int].join(" ")) 
        end
      end
      out.puts "END IONS"
      out.puts ""
    end
  end
end
