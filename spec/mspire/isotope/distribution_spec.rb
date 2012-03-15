require 'spec_helper'

require 'mspire/isotope/distribution'

describe 'Mspire::Isotope::Distribution class methods' do
  before do 
    @data = [1.0, 0.08919230588715289, 0.017894161377222082, 0.0013573997600723623, 0.0001398330738144092]
  end

  it 'can calculate isotope distributions' do
    Mspire::Isotope::Distribution.calculate('C8O7', :max).should == @data
  end

  # no m/z values, just mass values
  it 'can calculate isotope distribution spectrum' do
    spec = Mspire::Isotope::Distribution.spectrum('C8O7', :max)
    spec.mzs.should == [207.96440233692, 208.97306725252, 209.98173216812, 210.99039708372, 211.99906199932002]
    spec.intensities.should == [1.0, 0.08919230588715289, 0.017894161377222082, 0.0013573997600723623, 0.0001398330738144092]
  end
end
