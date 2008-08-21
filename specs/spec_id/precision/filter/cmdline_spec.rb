require File.expand_path( File.dirname(__FILE__) + '/../../../spec_helper' )

require 'spec_id/precision/filter'

describe SpecID::Precision::Filter::CmdlineParser, 'getting all command line options correct' do

  before(:all) do
    @bioworks_file = Tfiles + '/bioworks_small.xml'
  end

  it_should 'gets all defaults correct with nothing passed in' do
    (spec_id_obj, options, option_parser) = SpecID::Precision::Filter::CmdlineParser.new.parse([@bioworks_file])
    p options
  end

  it_should 'gets all passed in params correct' do
  end

end

