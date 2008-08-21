require File.expand_path( File.dirname(__FILE__) + '/../../spec_helper' )

require 'spec_id/precision/prob'
require 'spec_id'
require 'spec_id/proph'
require 'validator'
require 'fasta'
require 'spec_id/sequest/params'


describe 'finding precision Proph::Prot::Pep objects' do
  before(:each) do
    @spec_id = GenericSpecID.new
    # actual sort order: 3, 0, 4, 1, 2
    peps = [
      # 0: canonical
      {:peptide_sequence => '0', :initial_probability => 0.63, :nsp_adjusted_probability => 0.62, :weight => 1.0, :is_nondegenerate_evidence => true, :n_enzymatic_termini => 2, :n_sibling_peptides => 0.0, :n_instances => 1, :is_contributing_evidence => true}, 
      # 1: lower init prob
      {:peptide_sequence => '1', :initial_probability => 0.60, :nsp_adjusted_probability => 0.62, :weight => 1.0, :is_nondegenerate_evidence => true, :n_enzymatic_termini => 2, :n_sibling_peptides => 0.0, :n_instances => 1, :is_contributing_evidence => true}, 
      # 2: lower nsp prob
      {:peptide_sequence => '2', :initial_probability => 0.63, :nsp_adjusted_probability => 0.52, :weight => 1.0, :is_nondegenerate_evidence => true, :n_enzymatic_termini => 2, :n_sibling_peptides => 0.0, :n_instances => 1, :is_contributing_evidence => true}, 
      # extra instances! (best hit)
      {:peptide_sequence => '3', :initial_probability => 0.63, :nsp_adjusted_probability => 0.62, :weight => 1.0, :is_nondegenerate_evidence => true, :n_enzymatic_termini => 2, :n_sibling_peptides => 0.0, :n_instances => 5, :is_contributing_evidence => true}, 
      # is nondegen = false 
      {:peptide_sequence => '4', :initial_probability => 0.63, :nsp_adjusted_probability => 0.62, :weight => 1.0, :is_nondegenerate_evidence => false, :n_enzymatic_termini => 2, :n_sibling_peptides => 0.0, :n_instances => 1, :is_contributing_evidence => true},].map {|v| Proph::Prot::Pep.new(v) }
      @spec_id.peps = peps
  end

  it 'runs without any validator' do
    answer = SpecID::Precision::Prob.new.precision_vs_num_hits(@spec_id) 
    answer.keys.map {|v| v.to_s }.sort.should == ["aaseqs", "charges", "count", "params", "pephits", "pephits_precision", "probabilities"]
    answer[:aaseqs].should == %w(3 0 4 1 2)
  end

  it 'returns modified peptides if any modified peptides' do
    @spec_id.peps[1].mod_info = Sequest::PepXML::SearchHit::ModificationInfo.new(['MODIFIED', []])
    answer = SpecID::Precision::Prob.new.precision_vs_num_hits(@spec_id) 
    answer.keys.map {|v| v.to_s }.sort.should == ["aaseqs", "charges", "count", "modified_peptides", "params", "pephits", "pephits_precision", "probabilities"]
  end

end



