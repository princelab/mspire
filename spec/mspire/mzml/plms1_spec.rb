require 'spec_helper'

require 'mspire/mzml'
require 'mspire/mzml/plms1'

describe 'converting mzml to plms1' do
  describe 'converting no spectra mzml' do
    before do 
      @mzml_file = File.open( TESTFILES + "/mspire/mzml/openms.noidx_nocomp.12.mzML" )
      @mzml = Mspire::Mzml.new(@mzml_file)
    end

    after do
      @mzml_file.close
    end

    it 'can be converted into a plms1 object' do
      scan_nums = [10929, 10931, 10933, 10935, 10937, 10939, 10940]
      times =[ 6604.58, 6605.91, 6606.98, 6607.93, 6608.92, 6609.94, 6610.53]
      plms1 = @mzml.to_plms1
      plms1.spectra.respond_to?(:each).should be_true
      plms1.times.should == times
      plms1.scan_numbers.should == scan_nums
      plms1.spectra.each do |spec|
        spec.should be_a_kind_of(Mspire::SpectrumLike)
        spec.mzs.should == []
        spec.intensities.should == []
      end
      #plms1.write("tmp.tmp.bin")
    end

  end

  describe 'converting normal mzml' do
    before do 
      @mzml_file = File.open( TESTFILES + "/mspire/mzml/j24z.idx_comp.3.mzML" )
      @mzml = Mspire::Mzml.new(@mzml_file)
    end

    after do
      @mzml_file.close
    end

    it 'can be converted into a plms1 object' do
      plms1 = @mzml.to_plms1
      plms1.spectra.respond_to?(:each).should be_true
      plms1.times.should == [1981.5726]
      plms1.scan_numbers.should == [1]
      sizes = [20168]
      plms1.spectra.zip(sizes).each do |spec,exp_size|
        spec.should be_a_kind_of(Mspire::SpectrumLike)
        spec.size.should == 2
        spec.mzs.size.should == exp_size
        spec.intensities.size.should == exp_size
      end
    end

  end
end
