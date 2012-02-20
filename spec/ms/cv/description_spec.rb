require 'spec_helper'
require 'ms/cv/description'

describe MS::CV::Description do

  it 'deciphers short accession descriptions' do
    subject.param 'MS:1000004'  # sample mass
    subject.param 'IMS:1000042', 23 # max count of pixels x
    {cv_ref: 'MS', accession: 'MS:1000004', name: 'sample mass', value: nil}.each do |key,val|
      subject[0].send(key).should == val
    end
    {cv_ref: 'IMS', accession: 'IMS:1000042', name: 'max count of pixels x', value: 23}.each do |key,val|
      subject[1].send(key).should == val
    end
  end

  it 'can be done with brackets' do
    param_obj = MS::CV::Param[ 'MS:1000055' ]  # an example of an object already made
    cvlist = MS::CV::Description['MS:1000004', ['MS:1000004'], ['IMS:1000042', 23], param_obj]
    cvlist.size.should == 4
    cvlist[0].should == cvlist[1]
    cvlist.each do |par|
      par.accession.should_not be_nil
      par.name.should_not be_nil
      par.cv_ref.should_not be_nil
    end
  end
end
