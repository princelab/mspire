require 'spec_helper'

require 'yaml'
path = 'mspire/ident/peptide/db'
require path 

module Kernel
 
  def capture_stdout
    out = StringIO.new
    $stdout = out
    yield
    out.rewind
    return out.read
  ensure
    $stdout = STDOUT
  end
 
end


describe 'a uniprot fasta file' do

  before do
    @fasta_file = [TESTFILES, path, 'uni_11_sp_tr.fasta'].join('/')
  end

  describe 'amino acid expansion' do

    it 'can expand out wildcard amino acid combinations' do
      array = Mspire::Ident::Peptide::Db.expand_peptides('ALXX', 'X' =>  %w(* % &), 'L' => %w(P Q) )
      array.sort.should == %w(AP** AP*% AP*& AP%* AP%% AP%& AP&* AP&% AP&& AQ** AQ*% AQ*& AQ%* AQ%% AQ%& AQ&* AQ&% AQ&&).sort
    end

    it 'will not expand explosive combinations (>MAX_NUM_AA_EXPANSION)' do
      # this is from real data
      worst_case = 'LTLLRPEKHEAATGVDTICTHRVDPIGPGLXXEXLYWELSXLTXXIXELGPYTLDR'
      Mspire::Ident::Peptide::Db.expand_peptides(worst_case, 'X' =>  %w(* % &)).nil?.should == true
    end

    it 'returns the peptide in the array if no expansion' do
      array = Mspire::Ident::Peptide::Db.expand_peptides('ZZZZZ', 'X' =>  %w(* % &), 'L' => %w(P Q) )
      array.should == ['ZZZZZ']
    end

  end

  describe 'creating a peptide centric database' do
    before do

      #@output_file = [TESTFILES, path, 'uni_11_sp_tr.'].join('/')
      @output_file = [TESTFILES, path, "uni_11_sp_tr.msd_clvg2.min_aaseq4.yml"].join('/')
    end

    it 'converts a fasta file into peptide centric db' do
      output_files = Mspire::Ident::Peptide::Db.cmdline([@fasta_file])
      output_files.first.should == File.expand_path(@output_file)
      File.exist?(@output_file).should == true
      hash = {}
      YAML.load_file(@output_file).each do |k,v|
        hash[k] = v.split("\t")
      end
      sorted = hash.sort
      # these are merely frozen, not perfectly defined
      sorted.first.should == ["AAFDDAIAELDTLSEESYK", ["sp|P62258|1433E_HUMAN"]]
      sorted.last.should == ["YWCRLGPPRWICQTIVSTNQYTHHR", ["tr|D2KTA8|D2KTA8_HUMAN"]]
      sorted.size.should == 728
      File.unlink(@output_file)
    end

    it 'lists approved enzymes and exits' do
      output = capture_stdout do
        begin
          Mspire::Ident::Peptide::Db.cmdline(['--list-enzymes'])
        rescue SystemExit
          1.should == 1 # we exited
        end
      end
      lines = output.split("\n")
      lines.include?("trypsin").should == true
      lines.include?("chymotrypsin").should == true
    end
  end

  describe 'reading a peptide centric database' do
    before do
      outfiles = Mspire::Ident::Peptide::Db.cmdline([@fasta_file])
      @outfile = outfiles.first
    end

    it 'creates a hash that can retrieve peptides as an array' do
      hash = Mspire::Ident::Peptide::Db.new(@outfile)
      hash["AVTEQGHELSNEER"].should == %w(sp|P31946|1433B_HUMAN	sp|P31946-2|1433B_HUMAN)
      hash["VRAAR"].should == ["tr|D3DX18|D3DX18_HUMAN"]
    end

    it 'reads the file on disk with random access or is enumerable' do
      Mspire::Ident::Peptide::Db::IO.open(@outfile) do |io|
        io["AVTEQGHELSNEER"].should == %w(sp|P31946|1433B_HUMAN	sp|P31946-2|1433B_HUMAN)
        io["VRAAR"].should == ["tr|D3DX18|D3DX18_HUMAN"]
        io.each_with_index do |key_prots, i|
          key_prots.first.should be_an_instance_of String
          key_prots.last.should be_a_kind_of Array
        end
      end
    end
  end
end
