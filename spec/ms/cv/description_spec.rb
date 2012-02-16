require 'spec_helper'
require 'ms/cv/description'
require 'cv'

describe 'appending CV params objects to an MS::CV::Description' do
  describe 'intelligently appending params with #param' do
    before do
      @cv = MS::CV::Description.new
    end
    it 'sends detailed descriptions to CV::Param.new' do
      arglist = [
        ['IMS', 'IMS:1000052', 'position z', 22],
        ['IMS', 'IMS:1000030', 'continuous'],
        ['IMS', 'IMS:1000052', 'position z', 22, 'UO:0000008'],
        ['IMS', 'IMS:1000030', 'continuous', 'UO:0000008'],
        ['IMS', 'IMS:1000052', 'position z', 22, MS::CV::Param.new('UO:0000008')],
        ['IMS', 'IMS:1000030', 'continuous', MS::CV::Param.new('UO:0000008')],
      ]
      arglist.each do |args|
        @cv.param *args
      end
      @cv.size.should == arglist.size
      arglist.each_with_index do |args, i|
        @cv[i].should == MS::CV::Param.new(*args)
      end
    end
    it 'deciphers short accession descriptions' do
      @cv.param 'MS:1000004'  # sample mass
      @cv.param 'IMS:1000042', 23 # max count of pixels x
      {cv_ref: 'MS', accession: 'MS:1000004', name: 'sample mass', value: nil}.each do |key,val|
        @cv[0].send(key).should == val
      end
      {cv_ref: 'IMS', accession: 'IMS:1000042', name: 'max count of pixels x', value: 23}.each do |key,val|
        @cv[1].send(key).should == val
      end
    end
    describe 'appending on initialization' do
      it 'can be done with a block' do
        cvlist = MS::CV::Description.new do
          param 'MS:1000004'  # sample mass
          param 'IMS:1000042', 23 # max count of pixels of y
        end
        cvlist.size.should == 2
      end
    end

    it 'can be done with brackets' do
      args = ['IMS', 'IMS:1000052', 'position z', 22]
      param_obj = CV::Param.new(*args)
      cvlist = MS::CV::Description['MS:1000004', ['MS:1000004'], ['IMS:1000042', 23], param_obj, args]
      cvlist.size.should == 5
      cvlist[0].should == cvlist[1]
      cvlist.each do |param|
        param.accession.should_not be_nil
        param.name.should_not be_nil
        param.cv_ref.should_not be_nil
      end
    end
  end
end
