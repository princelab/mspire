require 'spec_helper'

require 'mspire/mzml/source_file'
require 'builder'

describe 'making a SourceFile' do
  it 'can be generated with params and a block' do
    source_file = Mspire::Mzml::SourceFile.new("someFileID", "filename.mzML", "/home/jtprince/tmp").describe!('MS:1000584')

    params = source_file.params
    params.size.should == 1
    params.all? {|par| par.class == ::CV::Param }.should be_true
    b = Builder::XmlMarkup.new(:indent => 2)
    source_file.to_xml(b)
    xml = b.to_xml
    [/<sourceFile/, /id="some/, /name="filen/, /location="\/home/, /cvRef="MS"/].each do |regexp|
      xml.should match(regexp)
    end
  end

end


