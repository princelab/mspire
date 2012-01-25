require 'spec_helper'

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
  end
end


