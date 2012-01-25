require 'spec_helper'

require 'ms/mzml'
require 'ms/mzml/plms1'

describe 'converting mzml to plms1' do
  describe 'converting no spectra mzml' do
    before do 
      @mzml_file = File.open( TESTFILES + "/ms/mzml/openms.noidx_nocomp.12.mzML" )
      @mzml = MS::Mzml.new(@mzml_file)
    end

    after do
      @mzml_file.close
    end

    it 'can be converted into a plms1 object' do
      scan_nums = (10929..10940).to_a
      times =[6604.58, 6605.5, 6605.91, 6606.48, 6606.98, 6607.53, 6607.93, 6608.49, 6608.92, 6609.49, 6609.94, 6610.53]
      plms1 = @mzml.to_plms1
      plms1.spectra.respond_to?(:each).should be_true
      plms1.times.should == times
      plms1.scan_numbers.should == scan_nums
      plms1.spectra.each do |spec|
        p spec.size
        p spec.class
        p spec.mzs
        p spec.intensities
      end
      plms1.write("tmp.tmp.bin")
    end

  end

  describe 'converting normal mzml' do
    before do 
      @mzml_file = File.open( TESTFILES + "/ms/mzml/j24z.idx_comp.3.mzML" )
      @mzml = MS::Mzml.new(@mzml_file)
    end

    after do
      @mzml_file.close
    end

    it 'can be converted into a plms1 object' do
      #scan_nums = ###
      #times =[6604.58, 6605.5, 6605.91, 6606.48, 6606.98, 6607.53, 6607.93, 6608.49, 6608.92, 6609.49, 6609.94, 6610.53]
      plms1 = @mzml.to_plms1
      plms1.spectra.respond_to?(:each).should be_true
      p plms1.times
      p plms1.scan_numbers
      plms1.spectra.each do |spec|
        p spec.size
        p spec.class
        p spec.mzs.size
        p spec.intensities.size
      end
      #plms1.write("tmp.tmp.bin")
    end

  end
end
