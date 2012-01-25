require 'spec_helper'

require 'ms/ident/protein_group'

PeptideHit = Struct.new(:aaseq, :charge, :proteins) do
  def inspect # easier to read output
    "<PeptideHit aaseq=#{self.aaseq} charge=#{self.charge} proteins(ids)=#{self.proteins.map(&:id).join(',')}>"
  end
  def hash ; self.object_id end
end
ProteinHit = Struct.new(:id) do
  def inspect # easier to read output
    "<Prt #{self.id}>"
  end
  def hash ; self.object_id end
end

describe 'creating minimal protein groups from peptide hits' do
  before do
    @pep_hits = [ ['AABBCCDD', 2], 
      ['BBCC', 2],
      ['DDEEFFGG', 2],
      ['DDEEFFGG', 3],
      ['HIYA', 2],
    ].map {|ar| PeptideHit.new(ar[0], ar[1], []) }
    @prot_hits_hash = { 
      'big_guy' => @pep_hits,
      'little_guy' => [@pep_hits.last],
      'medium_guy1' => @pep_hits[0,4],
      'medium_guy2' => @pep_hits[0,4],
      'subsumed_by_medium' => @pep_hits[2,2],
    }
    @prot_hits = @prot_hits_hash.keys.map {|id| ProteinHit.new(id) }
  end

  it 'is a greedy algorithm' do
    @prot_hits.each {|prthit| @prot_hits_hash[prthit.id].each {|pep| pep.proteins << prthit } }
    # big_guy has all the peptides, so it takes them all
    protein_groups = MS::Ident::ProteinGroup.peptide_hits_to_protein_groups(@pep_hits)
    protein_groups.first.size.should == 1# the group
    protein_groups.first.first.id.should == 'big_guy'
  end

  it 'removes proteins accounted for only as little pieces of larger proteins' do
    @prot_hits[1..-1].each {|prthit| @prot_hits_hash[prthit.id].each {|pep| pep.proteins << prthit } }
    protein_groups = MS::Ident::ProteinGroup.peptide_hits_to_protein_groups(@pep_hits)
    # no subsumed_by_medium
    protein_groups.any? {|prot_group| prot_group.any? {|v| v.id == 'subsumed_by_medium' }}.should == false
  end

  it 'allows alternate sorting algorithms for greediness' do
    @prot_hits.each {|prthit| @prot_hits_hash[prthit.id].each {|pep| pep.proteins << prthit } }
    prot_groups = MS::Ident::ProteinGroup.peptide_hits_to_protein_groups(@pep_hits) do |prot_and_peptide_hits|
      # deliberate using a counterintuitive sorting method to give little guys
      # a chance
      -prot_and_peptide_hits.last.size
    end
    # because the little proteins are given priority, they 'survive'. Bigger
    # proteins may also survive if they have at least one unique peptide
    # to add to the mix.  This demonstrates how proteins can be weighted in
    # different ways based on their peptide hits.
    seen = []
    prot_groups.each {|pg| pg.each {|prot| seen << prot.id } }
    # big guy is completely accounted for in the now prioritized little guy
    # and medium guys, etc.
    seen.sort.should == @prot_hits_hash.keys[1..-1].sort
  end
end
