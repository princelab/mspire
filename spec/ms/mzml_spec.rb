require 'spec_helper'
require 'builder'

require 'ms/mzml'

describe MS::Mzml do

  describe 'reading an indexed, compressed peaks, mzML file' do
    describe 'reading a spectrum' do

      before do
        @file = TESTFILES + "/ms/mzml/j24z.idx_comp.3.mzML"
        @io = File.open(@file)
        @mzml = MS::Mzml.new(@io)
      end
      after do
        @io.close
      end

      it '#spectrum (or #[]) returns a spectrum when queried by index (Integer)' do
        spectrum = @mzml.spectrum(1) # getting the second spectrum
        spectrum1 = @mzml[1] # can get with brackets
        spectrum.ms_level.should == 2
        spectrum.should == spectrum1
        spectrum.should be_a(MS::Mzml::Spectrum)
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
        spectrum.should be_a(MS::Mzml::Spectrum)
      end

      it 'goes through spectrum with #each or #each_spectrum' do
        mz_sizes = [20168, 315, 634]
        centroided = [false, true, true]
        @mzml.each do |spec|
          spec.mzs.size.should == mz_sizes.shift
          spec.centroided?.should == centroided.shift
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
        iter = MS::Mzml.foreach(@file)
        3.times { iter.next.mzs.size.should == mz_sizes.shift }
        lambda {iter.next}.should raise_error
      end

      it 'can gracefully determine the m/z with highest peak in select scans' do
        highest_mzs = MS::Mzml.foreach(@file).select {|v| v.ms_level > 1 }.map do |spec|
          spec.points.sort_by(&:last).first.first
        end
        highest_mzs.map(&:round).should == [453, 866]
      end
    end
  end

  describe 'writing mzml' do 

    def sanitize_version(string)
      string.gsub(/"mspire" version="([\.\d]+)"/, %Q{"mspire" version="X.X.X"})    
    end

    it 'writes MS1 and MS2 spectra' do
      # params: profile and ms_level 1
      spec1 = MS::Mzml::Spectrum.new('scan=1', params: ['MS:1000128', ['MS:1000511', 1]]) do |spec|
        spec.data_arrays = [[1,2,3], [4,5,6]]
        spec.scan_list = MS::Mzml::ScanList.new do |sl|
          scan = MS::Mzml::Scan.new do |scan|
            # retention time of 42 seconds
            scan.describe! ['MS:1000016', 40.0, 'UO:0000010']
          end
          sl << scan
        end
      end

      # centroid,  ms_level 2, MSn spectrum, 
      spec_params = ['MS:1000127', ['MS:1000511', 2], "MS:1000580"]

      spec2 = MS::Mzml::Spectrum.new('scan=2', params: spec_params) do |spec| 
        spec.data_arrays = [[1,2,3.5], [5,6,5]]
        spec.scan_list = MS::Mzml::ScanList.new do |sl|
          scan = MS::Mzml::Scan.new do |scan|
            # retention time of 42 seconds
            scan.describe! ['MS:1000016', 45.0, 'UO:0000010']
          end
          sl << scan
        end
        precursor = MS::Mzml::Precursor.new( spec1 )
        si = MS::Mzml::SelectedIon.new
        # the selected ion m/z:
        si.describe! ["MS:1000744", 2.0]
        # the selected ion charge state
        si.describe! ["MS:1000041", 2]
        # the selected ion intensity
        si.describe! ["MS:1000042", 5]
        precursor.selected_ions = [si]
        spec.precursors = [precursor]
      end

      mzml = MS::Mzml.new do |mzml|
        mzml.id = 'ms1_and_ms2'
        mzml.cvs = MS::Mzml::CV::DEFAULT_CVS
        mzml.file_description = MS::Mzml::FileDescription.new  do |fd|
          fd.file_content = MS::Mzml::FileContent.new
          fd.source_files << MS::Mzml::SourceFile.new
        end
        default_instrument_config = MS::Mzml::InstrumentConfiguration.new("IC",[], params: ['MS:1000031'])
        mzml.instrument_configurations << default_instrument_config
        software = MS::Mzml::Software.new
        mzml.software_list << software
        default_data_processing = MS::Mzml::DataProcessing.new("did_nothing")
        mzml.data_processing_list << default_data_processing
        mzml.run = MS::Mzml::Run.new("little_run", default_instrument_config) do |run|
          spectrum_list = MS::Mzml::SpectrumList.new(default_data_processing)
          spectrum_list.push(spec1, spec2)
          run.spectrum_list = spectrum_list
        end
      end

      #check = TESTFILES + '/ms/mzml/mspire_simulated.noidx.check.mzML'
      tmpfile = TESTFILES + '/ms/mzml/mspire_simulated.MSn.TMP.mzML'
      mzml.to_xml(tmpfile)
      as_string = mzml.to_xml
      check_string = IO.read(TESTFILES + '/ms/mzml/mspire_simulated.MSn.check.mzML')

      [IO.read(tmpfile), as_string].each do |st|
        sanitize_version(check_string).should == sanitize_version(st)
      end
      #xml = sanitize_version(IO.read(tmpfile))
      #xml.should be_a(String)
      #sanitize_version(mzml.to_xml).should == xml
      #xml.should == sanitize_version(IO.read(check))
      #xml.should match(/<mzML/)
      #File.unlink(tmpfile)
    end


    it 'writes MS1 spectra and retention times' do

      spec_params = ['MS:1000127', ['MS:1000511', 1]]

      spec1 = MS::Mzml::Spectrum.new('scan=1', params: spec_params) do |spec|
        spec.data_arrays = [[1,2,3], [4,5,6]]
        spec.scan_list = MS::Mzml::ScanList.new do |sl|
          scan = MS::Mzml::Scan.new do |scan|
            # retention time of 42 seconds
            scan.describe! ['MS:1000016', 40.0, 'UO:0000010']
          end
          sl << scan
        end
      end
      spec2 = MS::Mzml::Spectrum.new('scan=2', params: spec_params) do |spec| 
        spec.data_arrays = [[1,2,3.5], [5,6,5]]
        spec.scan_list = MS::Mzml::ScanList.new do |sl|
          scan = MS::Mzml::Scan.new do |scan|
            # retention time of 42 seconds
            scan.describe! ['MS:1000016', 45.0, 'UO:0000010']
          end
          sl << scan
        end
      end

      mzml = MS::Mzml.new do |mzml|
        mzml.id = 'the_little_one'
        mzml.cvs = MS::Mzml::CV::DEFAULT_CVS
        mzml.file_description = MS::Mzml::FileDescription.new  do |fd|
          fd.file_content = MS::Mzml::FileContent.new
          fd.source_files << MS::Mzml::SourceFile.new
        end
        default_instrument_config = MS::Mzml::InstrumentConfiguration.new("IC",[], params: ['MS:1000031'])
        mzml.instrument_configurations << default_instrument_config
        software = MS::Mzml::Software.new
        mzml.software_list << software
        default_data_processing = MS::Mzml::DataProcessing.new("did_nothing")
        mzml.data_processing_list << default_data_processing
        mzml.run = MS::Mzml::Run.new("little_run", default_instrument_config) do |run|
          spectrum_list = MS::Mzml::SpectrumList.new(default_data_processing)
          spectrum_list.push(spec1, spec2)
          run.spectrum_list = spectrum_list
        end
      end

      check = TESTFILES + '/ms/mzml/mspire_simulated.noidx.check.mzML'
      tmpfile = TESTFILES + '/ms/mzml/mspire_simulated.TMP.mzML'
      mzml.to_xml(tmpfile)
      xml = sanitize_version(IO.read(tmpfile))
      xml.should be_a(String)
      sanitize_version(mzml.to_xml).should == xml
      xml.should == sanitize_version(IO.read(check))
      xml.should match(/<mzML/)
      File.unlink(tmpfile)
    end
  end
end

