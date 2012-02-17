require 'spec_helper'

require 'ms/mzml/writer'
require 'nokogiri'

describe MS::Mzml::Writer do

  it 'creates mzml xml' do
    writer = MS::Mzml::Writer.new
    xml_string = writer.to_xml do |xml|
      xml.should be_a(Nokogiri::XML::Builder)
    end
    xml_string.should be_a(String)
    [/xmlns/, /xsi/, /xsd/, /version/].each do |regexp|
      xml_string.should match(regexp)
    end
  end

  it 'can write to a builder object' do
    writer = MS::Mzml::Writer.new
    builder = Nokogiri::XML::Builder.new
    revised = writer.to_xml(builder) do |xml|
      xml.should be_a(Nokogiri::XML::Builder)
    end
    revised.should == builder
    revised.should be_a(Nokogiri::XML::Builder)
    xml_string = revised.to_xml
    [/xmlns/, /xsi/, /xsd/, /version/].each do |regexp|
      xml_string.should match(regexp)
    end
  end

end
