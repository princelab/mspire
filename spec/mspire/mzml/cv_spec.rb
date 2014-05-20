require 'spec_helper'
require 'builder'
require 'mspire/mzml/cv'

describe Mspire::Mzml::CV do
  
  it 'can make CVList xml' do
    cvs = [Mspire::Mzml::CV::MS, Mspire::Mzml::CV::UO, Mspire::Mzml::CV::IMS]
    cvs.each do |cv|
      [true, false].each do |ext|
        cv.basename(ext)
      end
    end
 
    b = Builder::XmlMarkup.new(:indent => 2)
    Mspire::Mzml::CV.list_xml(cvs, b)
    xml = b.to_xml
    [/cvList\s+count=/, /id="MS"/, /id="UO"/, /id="IMS"/, /URI="/].each do |regexp|
      xml.should match(regexp)
    end
  end

end
