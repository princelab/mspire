require 'spec_helper'

require 'mspire/mass/aa'

describe Mspire::Mass::AA do
  it 'provides string and symbol access to element masses' do
    mono = Mspire::Mass::AA::MONO

    mono['C'].should == 103.0091844778
    mono[:C].should == mono['C']

    Mspire::Mass::AA[:C].should == mono[:C] # <- not a hash but a method

    avg = Mspire::Mass::AA::AVG
    avg['C'].should == 103.1429
    avg[:C].should == avg['C']
  end
end
