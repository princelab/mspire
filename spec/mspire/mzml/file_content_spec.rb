require 'spec_helper'
require 'builder'

require 'mspire/mzml/file_content'

describe Mspire::Mzml::FileContent do 

  it 'can be initialized with params' do
    filecontent = Mspire::Mzml::FileContent.new(:params => ['MS:1000579', ['IMS:1000080', "{9D501BDC-5344-4916-B7E9-7E795B02C856}"]])

    desc = filecontent.params
    desc.size.should == 2
    desc.all? {|par| par.class == Mspire::CV::Param }.should be_true
    b = Builder::XmlMarkup.new
    filecontent.to_xml(b)
    xml = b.to_xml
    [/<fileContent>/, /cvRef="MS"/, /name="universally/].each do |regexp|
      xml.should match(regexp)
    end
  end


end


