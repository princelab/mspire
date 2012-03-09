require 'spec_helper'
require 'ms/mzml/file_description'
require 'builder'

describe 'creating mzml xml' do
  describe 'making fileContent' do

    end

  describe 'making a SourceFile' do
    it 'can be generated with params and a block' do
      source_file = MS::Mzml::SourceFile.new("someFileID", "filename.mzML", "/home/jtprince/tmp", params: ['MS:1000584'])

      params = source_file.params
      params.size.should == 1
      params.all? {|par| par.class == MS::CV::Param }.should be_true
      b = Builder::XmlMarkup.new(:indent => 2)
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
