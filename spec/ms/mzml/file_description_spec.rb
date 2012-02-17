require 'spec_helper'
require 'ms/mzml/file_description'

describe 'creating mzml xml' do
  describe 'making fileContent' do

    it 'can be generated with a block' do
      filecontent = MS::Mzml::FileContent.new do
        param 'MS:1000579'  # value-less param
        param 'IMS:1000080', "{9D501BDC-5344-4916-B7E9-7E795B02C856}"  # param with value
      end

      desc = filecontent.description
      desc.size.should == 2
      desc.all? {|par| par.class == MS::CV::Param }.should be_true
      b = Nokogiri::XML::Builder.new
      filecontent.to_xml(b)
      xml = b.to_xml
      [/<fileContent>/, /cvRef="MS"/, /name="universally/].each do |regexp|
        xml.should match(regexp)
      end
    end
  end

  describe 'making a SourceFile' do
    it 'can be generated with params and a block' do
      source_file = MS::Mzml::SourceFile.new("someFileID", "filename.mzML", "/home/jtprince/tmp") do
        param 'MS:1000584'  # an mzML file
      end

      desc = source_file.description
      desc.size.should == 1
      desc.all? {|par| par.class == MS::CV::Param }.should be_true
      b = Nokogiri::XML::Builder.new
      source_file.to_xml(b)
      xml = b.to_xml
      [/<sourceFile/, /id="some/, /name="filen/, /location="\/home/, /cvRef="MS"/].each do |regexp|
        xml.should match(regexp)
      end
    end

  end
  describe MS::Mzml::FileDescription do

    it 'creates valid xml' do
      #MS::Mzml::FileDescription

    end
  end
end
