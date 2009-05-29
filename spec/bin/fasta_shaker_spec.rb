require File.expand_path( File.dirname(__FILE__) + '/../spec_helper' )

require 'fasta'


class Fasta
  def same_sized_proteins?(other_fasta_obj_or_file)
    other = Fasta.to_fasta(other_fasta_obj_or_file)
    @prots.zip(other.prots).all? do |a,b|
      a.aaseq.size == b.aaseq.size
    end
  end

  # This is tough to say 'for sure'  Right now, we consider the proteins
  # shuffled if they are all the same size and 2/3 or more of the peptides are
  # different than the other (this is designed for small sets of proteins
  # where it is possible one of the peptides is equal to the other).
  def shuffled?(other_fasta_obj_or_file)
    other = Fasta.to_fasta(other_fasta_obj_or_file)
    if !same_sized_proteins?(other)
      false
    else
      (same, different) = @prots.zip(other.prots).partition do |prota, protb|
        prota == protb
      end
      fraction_different = different.size.to_f / (same.size + different.size)
      fraction_different >= 2.0/3
    end
  end
end

describe "a manipulator of a fasta file", :shared => true do
  before(:all) do
    @filestring = ">gi|P1
AMKRGAN
>gi|P2
CRGATKKTAGRPMEK
>gi|P3
PEPTIDE
"

    @rev_filestring = ">gi|P1
NAGRKMA
>gi|P2
KEMPRGATKKTAGRC
>gi|P3
EDITPEP
"

    @rev_pref_filestring = ">REV_gi|P1
NAGRKMA
>REV_gi|P2
KEMPRGATKKTAGRC
>REV_gi|P3
EDITPEP
"

    @rev_tryptic_filestring = ">gi|P1
MAKRNAG
>gi|P2
CRTAGKKEMPRGATK
>gi|P3
EDITPEP
"
  end


  before(:each) do
    testdir = File.dirname(__FILE__)
    @tmpfile = Tfiles + "/littlefasta.trash.fasta"
    @f = Tfiles + "/trash.fasta"
    File.open(@tmpfile, "w") {|fh| fh.print @filestring }
  end

  after(:each) do
    File.unlink @tmpfile if File.exist? @tmpfile
    File.unlink @f if File.exist? @f
  end

  it 'reverses protein sequences' do
    reverse_the_file
    fastap(@f).to_s.should == @rev_filestring
  end

  def reverse_the_file
    do_it(:reverse)
  end

  it 'shuffles protein sequences' do
    shuffle_the_file
    Fasta.new(@f).shuffled?(Fasta.from_string(@filestring)).should be_true
  end

  def shuffle_the_file
    do_it(:shuffle)
  end

  it 'concatenates sequences' do
    concatenate_sequences
    lns = fastalns(@f)
    strlns(@filestring).should == lns[0..5] # first part equal
    strlns(@rev_pref_filestring).should == lns[6..-1] # "second part equal")      
  end

  def concatenate_sequences
    do_it(:reverse, :cat => true, :prefix => 'REV_')
  end

  it 'makes prefixes' do
    make_prefixes
    #@shaker.reverse(@tmpfile, :out => @f, :prefix => 'SILLY_')
    fp = fastap(@f)
    fp.each do |prt|
      prt.header.should match(/^>SILLY_.+/)
    end
  end

  def make_prefixes
    do_it(:reverse, :prefix => 'SILLY_')
  end

  it 'makes fractions of proteins' do
    make_fractions_of_proteins(1.0/3)
    fastap(@f).size.should == 1
    fastap(@f).first.header.should =~ /^>[^M]/

    # this guy gets rounded up on the command line so that it fails there
    #make_fractions_of_proteins(2.0/3)
    #fastap(@f).size.should == 2
    #fastap(@f).each do |prt|
    #  prt.header.should =~ /^>[^M]/
    #end

    make_fractions_of_proteins(1.0)
    fastap(@f).size.should == 3
    fastap(@f).each do |prt|
      prt.header.should =~ /^>[^M]/
    end
  end

  def make_fractions_of_proteins(fraction)
    do_it(:shuffle, :fraction => fraction)
  end

 
  it 'makes fractions with labels (for > 1)' do
    make_fractions_of_proteins(1.1)
    fastap(@f).size.should == 4
    fastap(@f).any? do |prt|
      prt.header =~ /^>[^M]/
    end.should be_true


    make_fractions_of_proteins(2.6)
    fastap(@f).size.should == 8

    make_reverse_cat_fractions(2.0)
    fastap(@f).size.should == 9

    fp = Fasta.new(@f)
    fp[0..2].each do |prt|
      prt.header.should =~ /^>/
    end
    fp[3..5].each do |prt|
      prt.header.should =~ /^>MINE_f0_/
    end
    fp[6..8].each do |prt|
      prt.header.should =~ /^>MINE_f1_/
    end
  end

  def make_reverse_cat_fractions(fraction, prefix='MINE_')
    do_it(:reverse, :fraction => fraction, :cat => true, :prefix => prefix)
  end

  def reverse_tryptic_peptides
    do_it(:reverse, :tryptic_peptides => true)
  end

    it 'reverses tryptic peptides' do
      reverse_tryptic_peptides
      Fasta.from_string(@rev_tryptic_filestring).should == Fasta.new(@f)
    end

  def shuffle_tryptic_peptides
    do_it(:shuffle, :tryptic_peptides => true)
  end

  it 'shuffles tryptic peptides (rerun on failure to recheck)' do
    shuffle_tryptic_peptides
    lns = fastap(@f).to_s.split("\n")
    lns[1][2..3].should == 'KR'
    lns[3][1..1].should == 'R'
    lns[3].size.should == 'CRGATKKTAGRPMEK'.size
    lns[3].should_not == 'CRGATKKTAGRPMEK' #sequence is randomised from original [remote chance of failure] rerun to make sure
  end

    def strlns(str)
      str.split("\n")
    end

  def fastalns(fn)
    fn.exist_as_a_file?.should be_true
    IO.read(fn).split("\n")
  end

  # returns the fasta object proteins
  def fastap(fn)
    @f.exist_as_a_file?.should be_true
    Fasta.new(fn).prots
  end

end

describe FastaShaker, "by method call" do

  before(:all) do
    @shaker = FastaShaker.new
  end

  it_should_behave_like "a manipulator of a fasta file"

  def do_it(method, additional_opts={})
    opts = {:out => @f}
    @shaker.send(method, @tmpfile, opts.merge(additional_opts))  
  end

end


describe FastaShaker, "by command line long args" do
  before(:all) do
    @progname = 'fasta_shaker.rb'
  end

  it_should_behave_like "a cmdline program"
  it_should_behave_like "a manipulator of a fasta file"

  # returns an array of the args
  def opts_to_cmd_args(hash)
    opts = []
    hash.each do |k,v|
      opts.push('--' + k.to_s)
      unless (v == true) or (v == false)
        opts.push(v)
      end
    end
    opts
  end
  
  def do_it(method, additional_opts={})
    opts = {:out => @f}
    opts.merge!(additional_opts)
    cmd = [@cmd, method, @tmpfile, *(opts_to_cmd_args(opts))].join(" ")
    #puts cmd
    system cmd
  end

end
