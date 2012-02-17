require 'spec_helper'
require 'nokogiri'

require 'ms/mzml/referenceable_param_group'

describe 'creating xml for a list of referenceable_param_groups' do

  it 'creates them with a class call' do
    # the id is required for these objects
    rfgroup1 = MS::Mzml::ReferenceableParamGroup.new("mzArray") do
      param 'MS:1000576' # no compression
      param 'MS:1000514' # m/z array
    end

    rfgroup2 = MS::Mzml::ReferenceableParamGroup.new("intensityArray") do
      param 'MS:1000576' # no compression
      param 'MS:1000515' # intensity array
    end

    b = Nokogiri::XML::Builder.new
    z = MS::Mzml::ReferenceableParamGroup.list_xml([rfgroup1, rfgroup2], b)
    b.should == z
    xml = b.to_xml
    [/referenceableParamGroupList.*count="2/, /cvParam.*cvRef/, /id="intensityArray"/].each do |regexp|
      xml.should match(regexp)
    end
  end


end
