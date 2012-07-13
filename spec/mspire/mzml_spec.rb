require 'spec_helper'

require 'builder'
require 'mspire/mzml'

describe Mspire::Mzml do

  describe 'reading a SIM file', :pending do
    before do
      @file = TESTFILES + "/mspire/mzml/1_BB7_SIM_478.5.mzML"
      @io = File.open(@file)
      @mzml = Mspire::Mzml.new(@io)
    end
    after do
      @io.close
    end

    specify '#chromatogram' do
      tic = @mzml.chromatogram(0)
      tic.id.should == 'TIC'

      sim = @mzml.chromatogram(1)
      sim.id.should == 'SIM SIC 478.5'
    end

    specify '#num_chromatograms' do
      @mzml.num_chromatograms.should == 2
    end

    specify '#each_chromatogram' do
      @mzml.each_chromatogram do |chrm|
        chrm.should be_a(Mspire::Mzml::Chromatogram)
        chrm.times.should be_an(Array)
        chrm.intensities.should be_an(Array)
        chrm.times.size.should == 72
        chrm.intensities.size.should == 72
      end
    end
  end

  describe 'reading an indexed, compressed peaks, mzML file' do

    describe 'reading the header things' do
      before do
        @file = TESTFILES + "/mspire/mzml/j24z.idx_comp.3.mzML"
        @io = File.open(@file)
        @mzml = Mspire::Mzml.new(@io)
      end
      after do
        @io.close
      end

      it 'reads the cvList' do
        cvs = @mzml.cvs
        cvs.size.should == 2
        cvs.first.id.should == 'MS'
        cvs.last.id.should == 'UO'
      end

      it 'reads the fileDescription' do
        fd = @mzml.file_description
        fd.should be_a(Mspire::Mzml::FileDescription)

        fc = fd.file_content
        fc.fetch_by_acc("MS:1000579").should be_true
        fc.fetch_by_acc("MS:1000580").should be_true
        fc.fetch_by_acc("MS:1000550").should be_false
        fc.params.size.should == 2

        sfs = fd.source_files
        sfs.size.should == 1
        sf = sfs.first
        sf.id.should == 'RAW1'
        sf.name.should == 'j24.raw'
        sf.location.should == 'file://.'
        sf.params.size.should == 3
        sha1 = sf.param_by_acc('MS:1000569')
        sha1.name.should == 'SHA-1'
        sha1.accession.should == 'MS:1000569'
        sha1.value.should == "6023d121fb6ca7f19fada3b6c5e4d5da09c95f12"
      end

      it 'reads the referenceableParamGroupList' do
        rpgs = @mzml.referenceable_param_groups
        rpgs.size.should == 1
        rpg = rpgs.first
        rpg.id.should == 'CommonInstrumentParams'
        prms = rpg.params
        prms.first.to_a.should == ["MS", "MS:1000449", "LTQ Orbitrap", nil, nil]
        prms.last.to_a.should == ["MS", "MS:1000529", "instrument serial number", "SN1025B", nil]
      end

      it 'reads the softwareList' do
      end

    end

    describe 'reading a spectrum', :pending do
      before do
        @file = TESTFILES + "/mspire/mzml/j24z.idx_comp.3.mzML"
        @io = File.open(@file)
        @mzml = Mspire::Mzml.new(@io)
      end
      after do
        @io.close
      end

      it '#spectrum (or #[]) returns a spectrum when queried by index (Integer)' do
        spectrum = @mzml.spectrum(1) # getting the second spectrum
        spectrum1 = @mzml[1] # can get with brackets
        spectrum.ms_level.should == 2
        spectrum.should == spectrum1
        spectrum.should be_a(Mspire::Mzml::Spectrum)
        spectrum.should respond_to(:mzs)
        spectrum.should respond_to(:intensities)
        spectrum.mzs.size.should == 315
        spectrum.intensities.size.should == 315
        spectrum.mzs[2].should be_within(1e-10).of(164.32693481445312)
      end

      it '#spectrum (or #[]) returns a spectrum when queried by id (String)' do
        spectrum = @mzml.spectrum("controllerType=0 controllerNumber=1 scan=2")
        spectrum1 = @mzml["controllerType=0 controllerNumber=1 scan=2"]
        spectrum.ms_level.should == 2
        spectrum.should == spectrum1
        spectrum.should be_a(Mspire::Mzml::Spectrum)
      end

      it 'goes through spectrum with #each or #each_spectrum' do
        mz_sizes = [20168, 315, 634]
        centroided_list = [false, true, true]
        @mzml.each do |spec|
          spec.mzs.size.should == mz_sizes.shift
          centroided = centroided_list.shift
          spec.centroided?.should == centroided
        end
      end

      it 'gets an enumerator if called without a block' do
        mz_sizes = [20168, 315, 634]
        iter = @mzml.each
        3.times { iter.next.mzs.size.should == mz_sizes.shift }
        lambda {iter.next}.should raise_error
      end

      it 'iterates with foreach' do
        mz_sizes = [20168, 315, 634]
        iter = Mspire::Mzml.foreach(@file)
        3.times { iter.next.mzs.size.should == mz_sizes.shift }
        lambda {iter.next}.should raise_error
      end

      # not quite ready for this one yet
      xit 'contains scans linked to their instrument config objects' do
        instr_config_first = @mzml.file_description.instrument_configurations[0]
        instr_config_last = @mzml.file_description.instrument_configurations[1]
        @mzml[0].scan_list.first.instrument_configuration.should == instr_config_first 
        @mzml[1].scan_list.first.instrument_configuration.should == instr_config_last
      end

      it 'can gracefully determine the m/z with highest peak in select scans' do
        highest_mzs = Mspire::Mzml.foreach(@file).select {|v| v.ms_level > 1 }.map do |spec|
          spec.peaks.sort_by(&:last).first.first
        end
        highest_mzs.map(&:round).should == [453, 866]
      end
    end
  end

  describe 'writing mzml', :pending do 

    def sanitize_version(string)
      string.gsub(/"mspire" version="([\.\d]+)"/, %Q{"mspire" version="X.X.X"})    
    end

    it 'writes MS1 and MS2 spectra' do
      # params: profile and ms_level 1
      spec1 = Mspire::Mzml::Spectrum.new('scan=1', params: ['MS:1000128', ['MS:1000511', 1]]) do |spec|
        spec.data_arrays = [[1,2,3], [4,5,6]]
        spec.scan_list = Mspire::Mzml::ScanList.new do |sl|
          scan = Mspire::Mzml::Scan.new do |scan|
            # retention time of 42 seconds
            scan.describe! 'MS:1000016', 40.0, 'UO:0000010'
          end
          sl << scan
        end
      end

      # centroid,  ms_level 2, MSn spectrum, 
      spec_params = ['MS:1000127', ['MS:1000511', 2], "MS:1000580"]

      spec2 = Mspire::Mzml::Spectrum.new('scan=2', params: spec_params) do |spec| 
        spec.data_arrays = [[1,2,3.5], [5,6,5]]
        spec.scan_list = Mspire::Mzml::ScanList.new do |sl|
          scan = Mspire::Mzml::Scan.new do |scan|
            # retention time of 42 seconds
            scan.describe! 'MS:1000016', 45.0, 'UO:0000010'
          end
          sl << scan
        end
        precursor = Mspire::Mzml::Precursor.new( spec1 )
        si = Mspire::Mzml::SelectedIon.new
        # the selected ion m/z:
        si.describe! "MS:1000744", 2.0
        # the selected ion charge state
        si.describe! "MS:1000041", 2
        # the selected ion intensity
        si.describe! "MS:1000042", 5
        precursor.selected_ions = [si]
        spec.precursors = [precursor]
      end

      mzml = Mspire::Mzml.new do |mzml|
        mzml.id = 'ms1_and_ms2'
        mzml.cvs = Mspire::Mzml::CV::DEFAULT_CVS
        mzml.file_description = Mspire::Mzml::FileDescription.new  do |fd|
          fd.file_content = Mspire::Mzml::FileContent.new
          fd.source_files << Mspire::Mzml::SourceFile.new
        end
        default_instrument_config = Mspire::Mzml::InstrumentConfiguration.new("IC",[], params: ['MS:1000031'])
        mzml.instrument_configurations << default_instrument_config
        software = Mspire::Mzml::Software.new
        mzml.software_list << software
        default_data_processing = Mspire::Mzml::DataProcessing.new("did_nothing")
        mzml.data_processing_list << default_data_processing
        mzml.run = Mspire::Mzml::Run.new("little_run", default_instrument_config) do |run|
          spectrum_list = Mspire::Mzml::SpectrumList.new(default_data_processing, [spec1, spec2])
          run.spectrum_list = spectrum_list
        end
      end

      #check = TESTFILES + '/mspire/mzml/mspire_simulated.noidx.check.mzML'
      tmpfile = TESTFILES + '/mspire/mzml/mspire_simulated.MSn.TMP.mzML'
      mzml.to_xml(tmpfile)
      as_string = mzml.to_xml
      check_string = IO.read(TESTFILES + '/mspire/mzml/mspire_simulated.MSn.check.mzML')

      [IO.read(tmpfile), as_string].each do |st|
        sanitize_version(check_string).should == sanitize_version(st)
      end
      File.unlink(tmpfile) if File.exist?(tmpfile)
    end
  end
end

