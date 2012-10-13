require 'spec_helper'

require 'yaml'
path = 'mspire/ident/peptide/db'
require path + "/creator" 

describe 'creating a peptide centric database' do
  subject { Mspire::Ident::Peptide::Db::Creator.new }

  describe 'amino acid expansion' do

    it 'can expand out wildcard amino acid combinations' do
      array = subject.expand_peptides('ALXX', 'X' =>  %w(* % &), 'L' => %w(P Q) )
      array.sort.should == %w(AP** AP*% AP*& AP%* AP%% AP%& AP&* AP&% AP&& AQ** AQ*% AQ*& AQ%* AQ%% AQ%& AQ&* AQ&% AQ&&).sort
    end

    it 'will not expand explosive combinations (>MAX_NUM_AA_EXPANSION)' do
      # this is from real data
      worst_case = 'LTLLRPEKHEAATGVDTICTHRVDPIGPGLXXEXLYWELSXLTXXIXELGPYTLDR'
      subject.expand_peptides(worst_case, 'X' =>  %w(* % &)).nil?.should == true
    end

    it 'returns the peptide in the array if no expansion' do
      array = subject.expand_peptides('ZZZZZ', 'X' =>  %w(* % &), 'L' => %w(P Q) )
      array.should == ['ZZZZZ']
    end
  end

  describe 'the commandline utility' do

    before do
      @fasta_file = [TESTFILES, path, 'uni_11_sp_tr.fasta'].join('/')
      @output_file = [TESTFILES, path, "uni_11_sp_tr.msd_clvg2.min_aaseq4.yml"].join('/')
    end

    it 'converts a fasta file into peptide centric db' do
      output_files = Mspire::Ident::Peptide::Db::Creator.cmdline([@fasta_file])
      output_files.first.should == File.expand_path(@output_file)
      File.exist?(@output_file).should == true
      hash = {}
      YAML.load_file(@output_file).each do |k,v|
        hash[k] = v.split("\t")
      end
      sorted = hash.sort
      # these are merely frozen, not perfectly defined
      sorted.first.should == ["AAFDDAIAELDTLSEESYK", ["P62258"]]
      sorted.last.should == ["YWCRLGPPRWICQTIVSTNQYTHHR", ["D2KTA8"]]
      sorted.size.should == 728
      #File.unlink(@output_file)
    end

    it 'can use a trie' do
      Mspire::Ident::Peptide::Db::Creator.cmdline([@fasta_file, '--trie'])
      triefile = TESTFILES + '/mspire/ident/peptide/db/uni_11_sp_tr.msd_clvg2.min_aaseq4'
      %w(.trie .tail .da).each do |ext|
        File.exist?(triefile + ext).should be_true
      end
      trie = Trie.read(triefile)
      p trie.get('MADGSGWQPPRPCEAYR')
      #trie.get('MADGSGWQPPRPCEAYR').should == ["D3DX18"]
    end

    it 'lists approved enzymes and exits' do
      output = capture_stdout do
        begin
          Mspire::Ident::Peptide::Db::Creator.cmdline(['--list-enzymes'])
        rescue SystemExit
          1.should == 1 # we exited
        end
      end
      lines = output.split("\n")
      lines.include?("trypsin").should == true
      lines.include?("chymotrypsin").should == true
    end
  end
end
