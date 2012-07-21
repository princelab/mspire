require 'spec_helper'

require 'mspire/mzml/spectrum_list'
require 'builder'

class MockSpectrum
  attr_accessor :index
  attr_accessor :id
  attr_accessor :source_file
  attr_accessor :data_processing
  def initialize(id)
    @id = id
  end
  def to_xml(builder, default_ids)
    builder.mockSpectrum {}
    builder
  end
end

MockObject = Struct.new(:id)

describe Mspire::Mzml::SpectrumList do

  let :speclist do
    Mspire::Mzml::SpectrumList.new(MockObject.new(:default_data_processing), [MockSpectrum.new('spec1')], { 'spec1' => 0 })
  end

  specify '#[Integer]' do
    speclist[0].id.should == 'spec1'
  end

  specify '#[id]' do
    speclist['spec1'].id.should == 'spec1'
  end

  specify '#create_id_to_index!' do
    orig_index = speclist.id_to_index
    speclist.create_id_to_index!
    new_index = speclist.id_to_index
    new_index.should == orig_index
    new_index.equal?(orig_index).should be_false
  end

  specify '#to_xml' do
    require 'stringio' 
    st = StringIO.new
    builder = Builder::XmlMarkup.new(:target => st)
    speclist.to_xml(builder, {})
    st.string.should == "<spectrumList count=\"1\" defaultDataProcessingRef=\"default_data_processing\"><mockSpectrum></mockSpectrum></spectrumList>"
  end

end

  
