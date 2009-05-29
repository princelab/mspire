require File.expand_path( File.dirname(__FILE__) + '/spec_helper' )
require 'gi'


describe GI, "given a 'GI' number" do
  before(:all) do
    @gi_num = 836805
  end
  it 'can query NCBI for annotation (fails nicely w/o connection)' do
    annot = GI.gi2annot([@gi_num])
    if annot
      annot.first.should == 'proteosome component PRE4 [Saccharomyces cerevisiae]'
    else
      puts "- retrieval of gi failed gracefully w/o internet connection"
    end
end

end




