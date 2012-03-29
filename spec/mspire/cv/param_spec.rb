require 'spec_helper'

require 'mspire/cv/param'
require 'cv/param'

describe Mspire::CV::Param do
  describe 'object creation from class method' do

    it '::[] expects shortcut accession strings' do
      param1 = Mspire::CV::Param['MS:1000052']
      param1.cv_ref.should == 'MS'
      param1.value.should be_nil

      # just nonsense: 32 ng suspensions
      param2 = Mspire::CV::Param['MS:1000052', 32, 'UO:0000024']
      param2.cv_ref.should == 'MS'
      param2.name.should == 'suspension'
      param2.value.should == 32
      param2.unit.accession.should == 'UO:0000024'
    end

    it 'casts values based on info in the obo itself' do
      param = Mspire::CV::Param['MS:1000005', "2.2"]
      param.value.should == 2.2
      param.value.should be_a(Float)
      param = Mspire::CV::Param['MS:1000041', "3"]
      param.value.should be_a(Integer)
      param.value.should == 3
      # doesn't get greedy about casting things like nil
      param = Mspire::CV::Param['MS:1000041', nil]
      param.value.should be_nil
    end

  end
end
