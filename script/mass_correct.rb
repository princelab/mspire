#!/usr/bin/env ruby

require 'rserve/simpler/R'
require 'runarray/narray'

MzDiffs = Struct.new(:mz, :intensity, :spectrum_id, :dev) do
  def abs_dev
    self.dev.abs
  end
end

# returns an array of spectrum_id => shift
def find_spectral_shifts(mz_theor, mz_diffs, dev_cutoff = 0.5)
  spec_id_to_shift = {}
  
  (close_diffs, far_diffs) = mz_diffs.partition {|diff| diff.abs_dev < dev_cutoff }
  
  close_mz_vals = close_diffs.map(&:mz)

  runarray = Runarray::NArray.new(close_mz_vals)
  outlier_indices = runarray.outliers_iteratively(3)
  
  # need the global shift
  tight_mz_vals = close_mz_vals.reject.with_index do |mz, i|
    outlier_indices.include?(i)
  end

  (mean, sd) = Runarray::NArray.new(tight_mz_vals).sample_stats

  global_shift = mean - mz_theor

  close_diffs.zip(close_mz_vals).each.with_index do |(mz_diff, mz_val),i|
  spec_id_to_shift[mz_diff.spectrum_id] =
    if outlier_indices.include?(i)
      global_shift
    else
      global_shift + (mz_val - mean)
    end
  end

  far_diffs.each {|mz_diff| spec_id_to_shift[mz_diff.spectrum_id] = global_shift }

  #pvalue = R.converse( mz_diffs: close_mz_vals ) do
  #  "shapiro.test(mz_diffs)$p.value"
  #end
  spec_id_to_shift
end

require 'optparse'
require 'mspire/mzml'
ext = ".massCorrected.mzML"
opt = {}
opts = OptionParser.new do |op|
  op.banner = "usage: #{File.basename($0)} [OPTS] <m/z> <file>.mzML ..."
  op.separator "output: <file>#{ext}"
  op.separator "finds the nearest m/z to <m/z> and shifts m/z values"
  op.separator "prints the corrected deviation to stdout"
  op.separator ""
  op.separator "options:"
  op.on("-t", "--threshold <Float>", Float, 'intensity must be above threshold') {|v| opt[:threshold] = v }
  op.on("-f", "--filter-string-regex <regex-no-slashes>", 'only match and calibrate if matches filter string') {|v| opt[:filter_string_regex] = Regexp.new(Regexp.escape(v)) }
end
opts.parse!

if ARGV.size == 0
  puts opts
  exit
end

threshold = opt[:threshold] || 0.0
filter_string_regex = opt[:filter_string_regex]

mz_theor = ARGV.shift.to_f

ARGV.each do |file|
  base = file.chomp(File.extname(file))
  outfile = base + ext

  mz_diffs = []
  Mspire::Mzml.open(file) do |mzml|
    #Finding the deviation
    mzml.each do |spectrum|
      if spectrum.ms_level == 1
        if filter_string_regex 
          next unless filter_string_regex.match(spectrum.scan_list.first.fetch_by_acc('MS:1000512'))
        end
        indices = spectrum.find_all_nearest_index(mz_theor)
        best_index = indices.max {|i| spectrum.intensities[i] }
        closest_mz = spectrum.mzs[best_index]
        mz_diffs << MzDiffs.new(closest_mz, spectrum.intensities[best_index], spectrum.id, closest_mz - mz_theor)
      end
    end

    spectral_shifts = find_spectral_shifts(mz_theor, mz_diffs)

    #correcting the masses
    spectra = mzml.map do |spectrum|
      if spectrum.ms_level == 1
        spectrum.mzs.map! do|mz|
          if (shift=spectral_shifts[spectrum.id])
            mz + shift
          else
            mz
          end
        end
        spectrum
      else
        spectrum
      end
    end  

    data_processing = Mspire::Mzml::DataProcessing.new("Corrected_Mass")
    mzml.data_processing_list << data_processing
    mzml.run.spectrum_list = Mspire::Mzml::SpectrumList.new(data_processing, spectra)
    mzml.write(outfile)
  end
end

