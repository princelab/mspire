require File.expand_path( File.dirname(__FILE__) + '/../../spec_helper' )
require 'spec_id/sequest/params'


describe "a sequest params object", :shared => true do
  before(:each) do
    @obj = Sequest::Params.new(@file)
  end
  it 'gives enzyme_specificity' do
    ar = @obj.enzyme_specificity
    ar.size.should == 3
    ar.should == @enzyme_specificity
  end
  it 'returns static mods callable by key' do
    @obj.add_Cterm_peptide.should == @add_Cterm_peptide
  end
end


describe Sequest::Params, "with a bioworks 3.1 params" do
  before(:all) do
    @file = Tfiles + '/bioworks31.params'
    @obj = Sequest::Params.new(@file)
    @enzyme_specificity = [1, 'KR', '']
    @add_Cterm_peptide = '0.0000'
  end
  it_should_behave_like 'a sequest params object'
end

describe Sequest::Params, "with a bioworks 3.2 params" do
  before(:all) do
    @file = Tfiles + '/bioworks32.params'
    @obj = Sequest::Params.new(@file)
    @enzyme_specificity = [1, 'KR', 'P']
    @add_Cterm_peptide = '0.0000'
  end
  it_should_behave_like 'a sequest params object'
end

describe Sequest::Params, "with a bioworks 3.3 params" do
  before(:all) do
    @file = Tfiles + '/bioworks33.params'
    @obj = Sequest::Params.new(@file)
    @enzyme_specificity = [1, 'KR', '']
    @add_Cterm_peptide = '0.0000'
  end
  it_should_behave_like 'a sequest params object'
end

describe Sequest::Params, "given a bioworks 3.2 params (from .srf file)" do
  before(:all) do
    @file = Tfiles + '/7MIX_STD_110802_1.sequest_params_fragment.srf'
    @obj = Sequest::Params.new(@file)
    @enzyme_specificity = [1, 'KR', 'P']
    @add_Cterm_peptide = '0.0000'
  end
  it_should_behave_like 'a sequest params object'
end


describe Sequest::Params do
  it '(private) can give a system independent basename' do
    Sequest::Params.new._sys_ind_basename("C:\\Xcalibur\\database\\hello.fasta").should == "hello.fasta"
    Sequest::Params.new._sys_ind_basename("/work/john/hello.fasta").should == "hello.fasta"
  end
  
end

