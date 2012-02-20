require 'spec_helper'
require 'builder'

require 'ms/mzml/referenceable_param_group'

describe MS::Mzml::ReferenceableParamGroup do

  it 'is created with an id and params' do
    # the id is required for these objects
    # no compression
    rfgroup1 = MS::Mzml::ReferenceableParamGroup.new("mzArray", 'MS:1000576', 'MS:1000514')
    rfgroup2 = MS::Mzml::ReferenceableParamGroup.new("intensityArray", 'MS:1000576', 'MS:1000515')

    b = Builder::XmlMarkup.new(:indent => 2)
    z = MS::Mzml::ReferenceableParamGroup.list_xml([rfgroup1, rfgroup2], b)
    xml = b.to_xml
    [/referenceableParamGroupList.*count="2/, /cvParam.*cvRef/, /id="intensityArray"/].each do |regexp|
      xml.should match(regexp)
    end
  end

  it '#to_xml gives a ReferenceableParamGroupRef' do
    rfgroup1 = MS::Mzml::ReferenceableParamGroup.new("mzArray", 'MS:1000576', 'MS:1000514')
    builder = Builder::XmlMarkup.new(:indent => 2)
    rfgroup1.to_xml(builder)
    xml = builder.to_xml
    [/referenceableParamGroupRef/, /ref="mzArray"/].each do |regexp|
      xml.should match(regexp)
    end
  end


end
