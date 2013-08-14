require 'spec_helper'

# we aren't testing for preciseness in these examples (that is done
# elsewhere), but we are verifying that it runs with no errors (i.e., the
# syntax and api is all current)

describe 'performing what is on the readme' do
  describe 'mzml' do
    let(:mzml_file) { TESTFILES + "/mspire/mzml/j24z.idx_comp.3.mzML" }
    let(:outfile) { TESTFILES + "/mspire/mzml/j24z.idx_comp.3.NORMALIZED.mzML" }

    specify "reading an mzml file" do

      reply = capture_stdout do

        require 'mspire/mzml'

        Mspire::Mzml.open(mzml_file) do |mzml|

          # random access by index or id (even if file wasn't indexed)
          spectrum = mzml[0]
          spectrum = mzml["controllerType=0 controllerNumber=1 scan=2"]

          spectrum.mzs
          spectrum.intensities

          # first 5 peaks
          spectrum.peaks[0,5].each do |mz, intensity|
            puts "#{mz} #{intensity}"
          end

          # true if key exists and no value, the value if present, or false
          if spectrum.fetch_by_acc('MS:1000128')
            puts "this is a profile spectrum!"
          end

          if spectrum.ms_level == 2
            low_mz = spectrum.scan_list.first.scan_windows.first.fetch_by_acc("MS:1000501").to_i
            puts "begin scan at #{low_mz} m/z"
          end
        end

      end
      reply.each_line.map.to_a.size.should == 6
      reply.include?('begin scan at 120').should be_true
    end

    specify "normalizing and writing an mzml file" do
      require 'mspire/mzml'

      Mspire::Mzml.open(mzml_file) do |mzml|

        # MS:1000584 -> an mzML file
        mzml.file_description.source_files << Mspire::Mzml::SourceFile[mzml_file].describe!('MS:1000584')
        mspire = Mspire::Mzml::Software.new
        mzml.software_list.push(mspire).uniq_by(&:id)
        normalize_processing = Mspire::Mzml::DataProcessing.new("ms1_normalization") do |dp|
          # 'MS:1001484' -> intensity normalization 
          dp.processing_methods << Mspire::Mzml::ProcessingMethod.new(mspire).describe!('MS:1001484')
        end

        mzml.data_processing_list << normalize_processing

        spectra = mzml.map do |spectrum|
          normalizer = 100.0 / spectrum.intensities.max
          spectrum.intensities.map! {|i| i * normalizer }
          spectrum
        end
        mzml.run.spectrum_list = Mspire::Mzml::SpectrumList.new(normalize_processing, spectra)
        mzml.write(outfile)
      end
      file_check(outfile) do |string|
        sanitize_mspire_version_xml(string)
      end
    end

  end

  specify 'masses' do
    require 'mspire/mass/aa'

    # very high precision NIST masses
    aa_to_mass = Mspire::Mass::AA::MONO # a hash with residue masses
    aa_to_mass['A'] # or access by symbol - Alanine

    Mspire::Mass::Element::MONO[:C] # carbon
    Mspire::Mass::Subatomic::MONO[:electron] # electron
  end

  specify 'isotopes and molecular formulas' do
    reply = capture_stdout do

      require 'mspire/isotope'
      isotopes = Mspire::Isotope::ISOTOPES  # 288 isotopes
      hydrogen_isotopes = isotopes.select {|iso| iso.element == :h }

      c12 = Mspire::Isotope::BY_ELEMENT[:C].first
      c12.atomic_number # also: mass_number atomic_mass relative_abundance average_mass
      c12.mono   # => true (this is the monoisotopic isotope)

      require 'mspire/molecular_formula'  # requires fftw gem
      propane = Mspire::MolecularFormula['C3H8']
      butane = propane + Mspire::MolecularFormula['CH2']
      puts butane  # => C4H10

      require 'mspire/isotope/distribution'  # requires fftw gem
      puts butane.isotope_distribution  # :total, :max, :first as arg to normalize
    end
  end

  specify 'digestion' do
    reply = capture_stdout do
      require 'mspire/digester'
      trypsin = Mspire::Digester[:trypsin]
      p trypsin.digest("AACCKDDEERFFKPGG") # => ["AACCK", "DDEER", "FFKPGG"]
    end
  end
end
