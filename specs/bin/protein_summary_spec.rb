require File.expand_path( File.dirname(__FILE__) + '/../spec_helper' )

describe 'protein_summary.rb' do

   before(:all) do
    @progname = 'protein_summary.rb'
  end
  it_should_behave_like 'a cmdline program'

  it 'outputs basic protein prophet -prot.xml summary' do

  end

end
