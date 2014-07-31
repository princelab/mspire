#!/usr/bin/env ruby

require 'mspire/mzml'

if ARGV.size == 0
  puts "usage: #{File.basename(__FILE__)} <file>.mzML ..."
  puts "output: <file>.baselined.mzML ..."
  puts "NOT SURE THIS IS WORKING JUST YET!!"
  exit
end

ARGV.each do |file|
  base = file.chomp(File.extname(file))
  outfile = base + ".baselined.mzML"

  Mspire::Mzml.open(file) do |mzml|

    # MS:1000584 -> an mzML file
    mzml.file_description.source_files << Mspire::Mzml::SourceFile[file].describe!('MS:1000584')
    mspire = Mspire::Mzml::Software.new
    mzml.software_list.push(mspire).uniq_by(&:id)
    processing = Mspire::Mzml::DataProcessing.new("simple_baseline_reduction") do |dp|
      # MS:1000593 baseline reduction
      dp.processing_methods << Mspire::Mzml::ProcessingMethod.new(mspire).describe!('MS:1000593')
    end

    mzml.data_processing_list << processing

    spectra = mzml.map do |spectrum|
      min_val = spectrum.intensities.min
      spectrum.intensities.map! {|i| i - min_val }
      spectrum
    end
    mzml.run.spectrum_list = Mspire::Mzml::SpectrumList.new(processing, spectra)
    mzml.write(outfile)
  end

end
