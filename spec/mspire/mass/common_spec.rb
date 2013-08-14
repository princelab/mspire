require 'spec_helper'

require 'mspire/mass/common'

describe Mspire::Mass::Common do
  it 'provides string and symbol access to common mass spec masses' do
    mono = Mspire::Mass::Common::MONO

    mono['OH'].should be_within(0.0000001).of( 17.002739651629998 )
    mono[:OH].should == mono['OH']
    Mspire::Mass::Common[:OH].should == mono[:OH]

    avg = Mspire::Mass::Common::AVG
    avg['OH'].should == 17.00734
    avg[:OH].should == avg['OH']
  end
end
