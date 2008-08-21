require File.expand_path( File.dirname(__FILE__) + '/../../../spec_helper' )
require 'spec_id/precision/filter'
require 'spec_id/precision/filter/output'

describe 'transforming hash with symbols into strings' do
  it 'works' do
    hash = {:one=>2, :this=>{:one=>"string", 3=>{:four=>5}}}
    new_hash = SpecID::Precision::Output.symbol_keys_to_string(hash)
    new_hash.should == {'one'=>2, 'this'=>{'one'=>"string", 3=>{'four'=>5}}}
  end
end

describe 'outputs' do
  before(:each) do
    @file = Tfiles + '/bioworks_with_INV_small.xml'
    @opts = {}
  end

  it 'makes a table' do
    my_file = Tfiles + '/filtering_tmp.tmp'
    File.unlink my_file if File.exist? my_file
    @opts[:output] = [[:text_table, my_file]]
    SpecID::Precision::Filter.new.filter_and_validate(SpecID.new(@file), @opts)  
    #reply = capture_stdout {
    #  SpecID::Precision::Filter.new.filter_and_validate(SpecID.new(@file), @opts)  
    #}
    # frozen
    IO.read(my_file) =~ /138/
    File.unlink my_file if File.exist? my_file
  end
end
