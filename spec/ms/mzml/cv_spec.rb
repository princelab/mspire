require 'spec_helper'
require 'builder'
require 'ms/mzml/cv'

describe MS::Mzml::CV do
  
  it 'can make CVList xml' do
    cvs = [MS::Mzml::CV::MS, MS::Mzml::CV::UO, MS::Mzml::CV::IMS]
    b = Builder::XmlMarkup.new(:indent => 2)
    MS::Mzml::CV.list_xml(cvs, b)
    xml = b.to_xml
    [/cvList\s+count=/, /id="MS"/, /id="UO"/, /id="IMS"/, /URI="/].each do |regexp|
      xml.should match(regexp)
    end
  end

end
