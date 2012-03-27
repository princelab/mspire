
require 'spec_helper'

require 'cv/param'

describe ::CV::Param do
  describe 'object creation from class methods' do

    it '::new allows full description' do
      param1 = ::CV::Param.new('MS', 'MS:1000052', 'suspension')
      param1.value.should be_nil
      # just nonsense: 32 ng suspensions
      param2 = ::CV::Param.new('MS', 'MS:1000052', 'suspension', 32, ::CV::Param.new('UO', 'UO:0000024', 'nanogram'))
      param2.cv_ref.should == 'MS'
      param2.value.should == 32
      param2.unit.accession.should == 'UO:0000024'
    end
  end
end


