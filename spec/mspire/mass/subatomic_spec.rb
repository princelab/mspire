require 'spec_helper'

require 'mspire/mass/subatomic'

describe Mspire::Mass::Subatomic do
  it 'provides string and symbol access to element masses' do
    mono = Mspire::Mass::Subatomic::MONO

    mono['neutron'].should == 1.0086649156
    mono[:neutron].should == mono['neutron']
    Mspire::Mass::Subatomic[:neutron].should == mono[:neutron]
  end
end
