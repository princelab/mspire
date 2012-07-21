require 'spec_helper'

require 'mspire/mzml'
require 'mspire/mzml/spectrum'

describe Mspire::Mzml::Spectrum do

  describe 'creating an ms1 spectrum from xml' do
    before(:all) do
      @io = File.open(TESTFILES + "/mspire/mzml/j24z.idx_comp.3.mzML")
      @mzml = Mspire::Mzml.new(@io)
    end

    after(:all) do
      @io.close
    end

    it 'gathers key data for ms1 spectrum' do
      spec = @mzml.run.spectrum_list[0]

      # convenient access to common attributes 
      spec.retention_time.should == 1981.5726
      spec.ms_level.should == 1

      spec.precursor_mz.should be_nil
      spec.precursor_charge.should be_nil

      # array info
      spec.mzs.size.should == 20168
      spec.intensities.size.should == 20168

      params = spec.params
      params.size.should == 9
      params.first.should be_a(::CV::Param)
    end

    it 'gathers key data for ms2 spectrum' do
      spec = @mzml.run.spectrum_list[1]

      # convenient access to common attributes 
      spec.retention_time.should == 1982.1077
      spec.ms_level.should == 2

      spec.precursor_mz.should == 479.7644958496094
      spec.precursor_charge.should == 2 

      # array info
      spec.mzs.size.should == 315
      spec.intensities.size.should == 315

      params = spec.params
      params.size.should == 9
      params.first.should be_a(::CV::Param)
    end

  end

end

