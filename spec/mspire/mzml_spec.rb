require 'spec_helper'

require 'builder'
require 'mspire/mzml'

require 'mspire/mzml/file_description'
require 'mspire/mzml/run'

describe Mspire::Mzml do

  describe 'reading a SIM file' do
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

  describe 'roundtrip: reading and then writing' do
    before do
      @file = TESTFILES + "/mspire/mzml/j24z.idx_comp.3.mzML"
    end

    it 'works' do
      outfile = TESTFILES + "/mspire/mzml/j24z.idx_comp.3.ROUNDTRIP.mzML"
      Mspire::Mzml.open(@file) do |mzml|
        mzml.write(outfile)
      end
      # I went through this file line by line to make sure it is correct
      # output.
      file_check(outfile)
    end
  end

  describe 'global normalizing spectra in a compressed mzML file (read in and write out)' do
    before do
      @file = TESTFILES + "/mspire/mzml/j24z.idx_comp.3.mzML"
    end

    specify 'normalize highest peak of each spectrum to 100' do
      outfile = TESTFILES + "/mspire/mzml/j24z.idx_comp.3.NORMALIZED.mzML" 

      Mspire::Mzml.open(@file) do |mzml|

        # MS:1000584 -> an mzML file
        mzml.file_description.source_files << Mspire::Mzml::SourceFile[@file].describe!('MS:1000584')
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
      # this output was checked to be accurate with TOPPView
      file_check(outfile) do |string|
        sanitize_mspire_version_xml(string)
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

      specify '#cvs - reads the cvList' do
        cvs = @mzml.cvs
        cvs.size.should == 2
        cvs.first.id.should == 'MS'
        cvs.last.id.should == 'UO'
      end

      specify '#file_description reads the fileDescription' do
        @mzml.file_description.should be_a(Mspire::Mzml::FileDescription)
      end

      describe Mspire::Mzml::FileDescription do

        let(:file_description) { @mzml.file_description }

        specify '#file_content' do
          fc = file_description.file_content
          fc.fetch_by_acc("MS:1000579").should be_true
          fc.fetch_by_acc("MS:1000580").should be_true
          fc.fetch_by_acc("MS:1000550").should be_false
          fc.params.size.should == 2
        end

        specify '#source_files' do
          sfs = file_description.source_files
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
      end

      specify '#referenceable_param_groups (reads the referenceableParamGroupList)' do
        rpgs = @mzml.referenceable_param_groups
        rpgs.size.should == 1
        rpg = rpgs.first
        rpg.id.should == 'CommonInstrumentParams'
        prms = rpg.params
        prms.first.to_a.should == ["MS", "MS:1000449", "LTQ Orbitrap", nil, nil]
        prms.last.to_a.should == ["MS", "MS:1000529", "instrument serial number", "SN1025B", nil]
      end

      it 'reads the softwareList' do
        sl = @mzml.software_list
        sl.size.should == 2
        xcal = sl.first
        xcal.id.should == 'Xcalibur'
        xcal.version.should == '2.4 SP1'
        xcal.params.first.to_a.should == ["MS", "MS:1000532", "Xcalibur", nil, nil]

        pwiz = sl.last
        pwiz.id.should == 'pwiz'
        pwiz.version.should == "2.1.2086"
        pwiz.params.first.to_a.should == ["MS", "MS:1000615", "ProteoWizard", nil, nil]
      end

      
      def component_is_correct(component, klass, accs)
        component.should be_a(Mspire::Mzml.const_get(klass))
        accs.each do |acc|
          component.fetch_by_acc(acc).should be_true
        end
      end

      it 'reads the instrumentConfigurationList' do
        ics = @mzml.instrument_configurations
        ics.size.should == 2
        ic1 = ics.first
        ic1.id.should == 'IC1'

        # grabbing a referenceable param!
        ic1.fetch_by_acc('MS:1000449').should be_true
        ic1.fetch_by_acc('MS:1000529').should be_true

        %w{Source Analyzer Detector}.zip(
          [["MS:1000398", "MS:1000485"], ["MS:1000484"], ["MS:1000624"]], 
          ic1.components
        ).each do |klass,accs,component|
          component_is_correct(component, klass, accs)
        end

        ic2 = ics.last

        %w{Source Analyzer Detector}.zip(
          [["MS:1000398", "MS:1000485"], ["MS:1000083"], ["MS:1000253"]], 
          ic2.components
        ).each do |klass,accs,component|
          component_is_correct(component, klass, accs)
        end
      end

      it 'reads the dataProcessingList' do
        dpl = @mzml.data_processing_list
        dpl.size.should == 1
        dp = dpl.first

        dp.id.should == 'pwiz_Reader_Thermo_conversion'
        pms = dp.processing_methods
        pms.size.should == 1
        pm = pms.first
        pm.should be_a(Mspire::Mzml::ProcessingMethod)

        # the order is not instrinsic to the object but to the container
        # (i.e., it is an index)
        dp.order(pm).should == 0
        pm.software.should be_a(Mspire::Mzml::Software)
        pm.params.first.to_a.should == ["MS", "MS:1000544", "Conversion to mzML", nil, nil]
      end

      it 'reads the run' do
        run = @mzml.run
        run.id.should == 'j24'

        ic = run.default_instrument_configuration
        ic.should be_a(Mspire::Mzml::InstrumentConfiguration)
        ic.fetch_by_acc('MS:1000449').should be_true

        run.start_time_stamp.should == "2010-07-08T11:34:52Z"
        sf = run.default_source_file
        sf.should be_a(Mspire::Mzml::SourceFile)
        sf.id.should == 'RAW1'

        run.sample.should be_nil # no sample
      end

      describe Mspire::Mzml::Run do

        specify '#spectrum_list' do
          sl = @mzml.run.spectrum_list
          sl.should be_a(Mspire::Mzml::SpectrumList)
          sl.default_data_processing.should be_a(Mspire::Mzml::DataProcessing)
          sl.default_data_processing.id.should == 'pwiz_Reader_Thermo_conversion'
          sl.size.should == 3

          sl.each do |spec|
            spec.should be_a(Mspire::Mzml::Spectrum)
            spec.params.size.should == 9
            scan_list = spec.scan_list
            scan_list.size.should == 1
            scan_list.params.size.should == 1
          end
        end

        specify '#chromatogram_list' do
          cl = @mzml.run.chromatogram_list
          cl.should be_a(Mspire::Mzml::ChromatogramList)
          cl.size.should == 1
          cl.default_data_processing.should be_a(Mspire::Mzml::DataProcessing)
          cl.default_data_processing.id.should == 'pwiz_Reader_Thermo_conversion'

          cl.each do |chrom|
            chrom.should be_a(Mspire::Mzml::Chromatogram)
          end
        end
      end
    end

    describe 'reading a spectrum' do
      before do
        @file = TESTFILES + "/mspire/mzml/j24z.idx_comp.3.mzML"
        @io = File.open(@file)
        @mzml = Mspire::Mzml.new(@io)
      end
      after do
        @io.close
      end

      specify '#spectrum (or #[]) returns a spectrum when queried by index (Integer)' do
        spectrum = @mzml.spectrum(1) # getting the second spectrum
        spectrum1 = @mzml[1] # can get with brackets
        spectrum.ms_level.should == 2
        spectrum.should == spectrum1
        spectrum.should be_a(Mspire::Mzml::Spectrum)
        spectrum.should respond_to(:mzs)
        spectrum.should respond_to(:intensities)

        spectrum.params.size.should == 9

        spectrum.mzs.size.should == 315
        spectrum.intensities.size.should == 315
        spectrum.mzs[2].should be_within(1e-10).of(164.32693481445312)
      end

      specify '#spectrum always returns spectrum with data_processing object (uses default if none given)' do
        @mzml.spectrum(1).data_processing.should be_a(Mspire::Mzml::DataProcessing)
      end

      specify '#spectrum (or #[]) returns a spectrum when queried by id (String)' do
        spectrum = @mzml.spectrum("controllerType=0 controllerNumber=1 scan=2")
        spectrum1 = @mzml["controllerType=0 controllerNumber=1 scan=2"]
        spectrum.ms_level.should == 2
        spectrum.should == spectrum1
        spectrum.should be_a(Mspire::Mzml::Spectrum)
      end

      specify '#each or #each_spectrum goes through each spectrum' do
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
        3.times { 
          iter.next.mzs.size.should == mz_sizes.shift 
        }
        lambda {iter.next}.should raise_error
      end

      it 'contains scans linked to their instrument config objects' do
        # this is tricky because we need to use the default instrument config
        # from the run for the first scan and an element ref for the second...
        [0,1].each do |i| 
          @mzml[i].scan_list.first.instrument_configuration.should be_a(Mspire::Mzml::InstrumentConfiguration)
        end
        instr_config_first = @mzml.instrument_configurations[0]
        instr_config_last = @mzml.instrument_configurations[1]

        @mzml[0].scan_list.first.instrument_configuration.should == instr_config_first 
        @mzml[1].scan_list.first.instrument_configuration.should == instr_config_last
      end

      it 'can gracefully determine the m/z with highest peak in select scans' do
        highest_mzs = Mspire::Mzml.foreach(@file).select {|v| v.ms_level > 1 }.map do |spec|
          spec.peaks.max_by(&:last)[0]
        end
        highest_mzs.map(&:round).should == [746, 644]
      end
    end
  end

  describe 'writing mzml' do 

    it 'writes MS1 and MS2 spectra' do
      spec1 = Mspire::Mzml::Spectrum.new('scan=1') do |spec|
        # profile and ms_level 1
        spec.describe_many!(['MS:1000128', ['MS:1000511', 1]])
        spec.data_arrays = [
          Mspire::Mzml::DataArray[1,2,3].describe!('MS:1000514'),  
          Mspire::Mzml::DataArray[4,5,6].describe!('MS:1000515')   
        ]
        spec.scan_list = Mspire::Mzml::ScanList.new do |sl|
          scan = Mspire::Mzml::Scan.new do |scan|
            # retention time of 42 seconds
            scan.describe! 'MS:1000016', 40.0, 'UO:0000010'
          end
          sl << scan
        end
      end

      spec2 = Mspire::Mzml::Spectrum.new('scan=2') do |spec| 
        # centroid,  ms_level 2, MSn spectrum, 
        spec.describe_many!(['MS:1000127', ['MS:1000511', 2], "MS:1000580"])
        spec.data_arrays = [
          Mspire::Mzml::DataArray[1,2,3.5].describe!('MS:1000514'),  
          Mspire::Mzml::DataArray[5,6,5].describe!('MS:1000515')   
        ]
        spec.scan_list = Mspire::Mzml::ScanList.new do |sl|
          scan = Mspire::Mzml::Scan.new do |scan|
            # retention time of 42 seconds
            scan.describe! 'MS:1000016', 45.0, 'UO:0000010'
          end
          sl << scan
        end
        precursor = Mspire::Mzml::Precursor.new( spec1.id )
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
        default_instrument_config = Mspire::Mzml::InstrumentConfiguration.new("IC").describe!('MS:1000031')
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

      tmpfile = TESTFILES + '/mspire/mzml/mspire_simulated.MSn.mzML'
      mzml.to_xml(tmpfile)
      as_string = mzml.to_xml
      as_string.should == IO.read(tmpfile)
      file_check(tmpfile) do |string|
        sanitize_mspire_version_xml(string)
      end
    end
  end
end

