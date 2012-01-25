require 'spec_helper'

require 'obo/ms'
require 'obo/ims'
require 'obo/unit'

describe 'accessing a specific Obo::Ontology' do
  it 'can access MS obo' do
    Obo::MS.id_to_name['MS:1000004'].should == 'sample mass'
    Obo::MS.name_to_id['sample mass'].should == 'MS:1000004'
    Obo::MS.id_to_element['MS:1000004'].should be_a(Obo::Stanza)
  end

  it 'can access IMS obo' do
    Obo::IMS.id_to_name['IMS:1000004'].should == 'image'
    Obo::IMS.name_to_id['image'].should == 'IMS:1000004'
    Obo::IMS.id_to_element['IMS:1000004'].should be_a(Obo::Stanza)
  end

  it 'can access Unit obo' do
    Obo::Unit.id_to_name['UO:0000005'].should == 'temperature unit'
    Obo::Unit.name_to_id['temperature unit'].should == 'UO:0000005'
    Obo::Unit.id_to_element['UO:0000005'].should be_a(Obo::Stanza)
  end
end
