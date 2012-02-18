require 'spec_helper'
require 'builder'

require 'ms/mzml'

describe 'indexed, compressed peaks, mzML file' do

  describe MS::Mzml do

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

    describe 'writing the simplest file with MS1 spectra' do
      spec1 = MS::Spectrum.new( [[1,2,3], [4,5,6]] )
      spec2 = MS::Spectrum.new( [[1,2,3.5], [5,6,5]] )

      MS::Mzml.new do |mzml|
        mzml.id = 'the_little_one'
        mzml.file_description = MS::Mzml::FileDescription.new  do |fd|
          fd.file_content = MS::Mzml::FileContent.new
          fd.source_files << MS::Mzml::SourceFile.new("text_data", "__simulated__")
        end
        default_instrument_config = MS::Mzml::InstrumentConfiguration.new("IC") do 
          param 'MS:1000031'  # instrument model (generic class)
          param :some_group_id
          param 'asdfas', 'asdfasdf'
        end
        mzml.instrument_configurations << default_instrument_config
        software = MS::Mzml::Software.new
        mzml.software_list << software
        default_data_processing = MS::Mzml::DataProcessing.new("did_nothing")
        mzml.data_processing << default_data_processing
        mzml.run = MS::Mzml::Run.new("little_run", default_instrument_config) do |run|
          spectrum_list = MS::Mzml::SpectrumList.new(default_data_processing)
          spectrum_list.add_spectra([spec1, spec2])
          run.spectrum_list = spectrum_list
        end
      end

    end

    describe 'writing xml' do

      xit 'creates mzml xml' do
        mzml = MS::Mzml.new
        xml_string = mzml.to_xml do |xml|
          xml.should be_a(Builder::XmlMarkup)
        end
        xml_string.should be_a(String)
        [/xmlns/, /xsi/, /xsd/, /version/].each do |regexp|
          xml_string.should match(regexp)
        end
      end

      xit 'can write to a builder object' do
        mzml = MS::Mzml.new
        builder = Nokogiri::XML::Builder.new
        revised = mzml.to_xml(builder) do |xml|
          xml.should be_a(Builder::XmlMarkup)
        end
        revised.should == builder
        revised.should be_a(Builder::XmlMarkup)
        xml_string = revised.to_xml
        [/xmlns/, /xsi/, /xsd/, /version/].each do |regexp|
          xml_string.should match(regexp)
        end
      end

    end
  end
end

