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
        spectrum1 = @mzml[1]
        spectrum.should == spectrum1
        spectrum.should be_a(MS::Spectrum)
        spectrum.should respond_to(:mzs)
        spectrum.should respond_to(:intensities)
        spectrum.mzs.size.should == 315
        spectrum.intensities.size.should == 315
        spectrum.mzs[2].should be_within(1e-10).of(164.32693481445312)
      end

      it '#spectrum (or #[]) returns a spectrum when queried by id (String)' do
        spectrum = @mzml.spectrum("controllerType=0 controllerNumber=1 scan=2")
        spectrum1 = @mzml["controllerType=0 controllerNumber=1 scan=2"]
        spectrum.should == spectrum1
        spectrum.should be_a(MS::Spectrum)
      end

      it 'goes through spectrum with #each or #each_spectrum' do
        mz_sizes = [20168, 315, 634]
        @mzml.each do |spec|
          spec.mzs.size.should == mz_sizes.shift
        end
      end
    end
  end

  describe 'writing mzml' do 

    it 'reads MS1 spectra and retention times' do

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
      xml = IO.read(tmpfile)
      xml.should be_a(String)
      mzml.to_xml.should == xml
      xml.should == IO.read(check)
      xml.should match(/<mzML/)
      File.unlink(tmpfile)
    end
  end
end

