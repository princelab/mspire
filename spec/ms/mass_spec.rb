require 'spec_helper'

describe 'MS::Mass' do
  it 'can access elemental masses by string or symbol' do
    MS::Mass::MONO['h'].should be_a_kind_of Float
    MS::Mass::MONO[:h].should be_a_kind_of Float
  end
end
