require 'spec_helper'

require 'mspire/mzml/data_array'

describe Mspire::Mzml::DataArray do

  it 'can be created from base64 binary data' do
    d_ar = Mspire::Mzml::DataArray.from_binary('eJxjYACBD/YMEOAAoTgcABe3Abg=', :float64, zlib=true)
    d_ar.is_a?(Array)
    d_ar.should == [1.0, 2.0, 3.0]
    d_ar = Mspire::Mzml::DataArray.from_binary('eJxjYACBD/YMEOAAoTgcABe3Abg=', ['MS:1000523', 'MS:1000574'])
    d_ar.is_a?(Array)
    d_ar.should == [1.0, 2.0, 3.0]
  end

  it "can be initialized like any ol' array" do
    data = [1,2,3]
    d_ar = Mspire::Mzml::DataArray.new( data )
    d_ar.should == data
  end

  describe 'an instantiated Mspire::Mzml::DataArray' do
    subject { Mspire::Mzml::DataArray.new [1,2,3] }

    it "can have a 'type'" do
      subject.type = :mz
      subject.type.should == :mz
    end

    it 'can be converted to a binary string' do
      string = subject.to_binary
      # frozen
      string.should == "eJxjYACBD/YMEOAAoTgcABe3Abg="
    end

  end

end
