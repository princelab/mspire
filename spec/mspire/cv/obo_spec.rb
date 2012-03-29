require 'spec_helper'

require 'mspire/cv/obo'

describe 'Mspire::CV::Obo' do
  it 'finds names based on id' do
    id_to_name = Mspire::CV::Obo::NAME
    id_to_name.should be_a(Hash)
    id_to_name['MS:1000005'].should == 'sample volume'
  end

  it 'finds casts based on id' do
    id_to_cast = Mspire::CV::Obo::CAST
    id_to_cast.should be_a(Hash)
    id_to_cast['MS:1000005'].should == :to_f
  end

end
