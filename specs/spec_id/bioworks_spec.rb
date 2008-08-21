require File.expand_path( File.dirname(__FILE__) + '/../spec_helper' )

require 'spec_id'
require 'spec_id/bioworks'
#require 'benchmark'

describe Bioworks, 'set from an xml file' do
  # NEED TO DEBUG THIS PROB!
  it 'can set one with labeled proteins' do
    file = Tfiles + "/bioworks_with_INV_small.xml"
    obj = Bioworks.new(file)
    obj.prots.size.should == 19
    file = Tfiles + '/bioworks_small.xml'
    obj = Bioworks.new(file)
    obj.prots.size.should == 106
  end

  it 'can parse an xml file NOT derived from multi-concensus' do
    tf_bioworks_single_xml_small = Tfiles + '/bioworks_single_run_small.xml'
    obj = Bioworks.new(tf_bioworks_single_xml_small)
    gfn = '5prot_mix_michrom_20fmol_200pmol'
    origfilename = '5prot_mix_michrom_20fmol_200pmol.RAW'
    origfilepath = 'C:\Xcalibur\sequest'
    obj.global_filename.should == gfn
    obj.origfilename.should == origfilename
    obj.origfilepath.should == origfilepath
    obj.prots.size.should == 7
    obj.prots.first.peps.first.base_name.should ==  gfn
    obj.prots.first.peps.first.file.should ==  "152"
    obj.prots.first.peps.first.charge.should == 2
    # @TODO: add more tests here
  end

  it 'can output in excel format (**semi-verified right now)' do
    tf_bioworks_to_excel = Tfiles + '/tf_bioworks2excel.bioXML'
    tf_bioworks_to_excel_actual = Tfiles + '/tf_bioworks2excel.txt.actual'
    tmpfile = Tfiles + "/tf_bioworks_to_excel.tmp"
    bio = Bioworks.new(tf_bioworks_to_excel)
    bio.to_excel(tmpfile)
    tmpfile.exist_as_a_file?.should be_true
    #File.should exist_as_a_file(tmpfile)
    exp = _arr_of_arrs(tf_bioworks_to_excel_actual)
    act = _arr_of_arrs(tmpfile)
    exp.each_index do |i|
      break if i == 23 ## this is where the ordering becomes arbitrary between guys with the same scans, but different filenames
      _assert_equal_pieces(exp[i], act[i], exp[i][0] =~ /\d/)
    end

    File.unlink tmpfile
  end

  # prot is boolean if this is a protein line!
  def _assert_equal_pieces(exp, act, prot)
    # equal as floats (by delta)
    exp.each_index do |i|
      if i == 5  # both prots and peps
        act[i].to_f.should be_close(exp[i].to_f, 0.1)
      elsif i == 3 && !prot
        act[i].to_f.should be_close(exp[i].to_f, 0.01)
      elsif i == 6 && !prot
        act[i].to_f.should be_close(exp[i].to_f, 0.01)
      elsif i == 9 && prot
        ## NEED TO GET THESE BACK (for consistency):
        #act[i].split(" ")[0].should =~ exp[i].split(" ")[0]
      else
        ## NEED TO GET THESE BACK (for consistency):
        #act[i].should == exp[i]
      end
    end
  end

  # takes a bioworks excel (in txt format) and outputs an arr of arrs
  def _arr_of_arrs(file)
    IO.readlines(file).collect do |line|
      line.chomp!
      line.split("\t")
    end
  end

  it 'can return unique peptides and proteins by sequence+charge (private)' do
    cnt = 0
    answer = [%w(2 PEPTIDE), %w(3 PEPTIDE), %w(3 PEPY), %w(2 PEPY)]
    exp_peps = answer.collect! do |arr|
      pep = Bioworks::Pep.new
      pep.charge = arr[0]
      pep.sequence = arr[1]
      pep
    end
    exp_prots = [[0,2],[1,4,5],[3],[6]].collect do |arr|
      arr.collect do |num|
        prot = Bioworks::Prot.new
        prot.reference = "#{num}"
        prot
      end
    end
    exp_peps = exp_peps.zip(exp_prots)
    exp_peps.collect! do |both|
      both[0].prots = [both[1]]
      both[0]
    end

    peptides = [%w(2 PEPTIDE), %w(3 PEPTIDE), %w(2 PEPTIDE), %w(3 PEPY), %w(3 PEPTIDE), %w(3 PEPTIDE), %w(2 PEPY)].collect do |arr|
      pep = Bioworks::Pep.new
      pep.charge = arr[0]
      pep.sequence = arr[1]
      pep.prots = [Bioworks::Prot.new]
      pep.prots.first.reference = "#{cnt}"
      cnt += 1
      pep
    end
    peptides, proteins = Bioworks.new._uniq_peps_by_sequence_charge(peptides)
    proteins.size.should == peptides.size
    exp_peps.each_with_index do |pep, i|
      peptides[i].charge.should == pep.charge
      peptides[i].sequence.should == pep.sequence
    end

    exp_prots.each_index do |i|
      exp_prots[i].each_index do |j|
        proteins[i][j].reference.should == exp_prots[i][j].reference
      end
    end
  end

end

describe Bioworks::Pep do
  it 'can be initialized from a hash' do
    hash = {:sequence => 0, :mass => 1, :deltamass => 2, :charge => 3, :xcorr => 4, :deltacn => 5, :sp => 6, :rsp => 7, :ions => 8, :count => 9, :tic => 10, :prots => 11, :base_name => 12, :first_scan => 13, :last_scan => 14, :peptide_probability => 15, :file => 16, :_num_prots => 17, :_first_prot => 18}
    pep = Bioworks::Pep.new(hash)
    hash.each do |k,v|
      pep.send(k).should == v
    end
  end

  it 'correctly extracts file information' do
    pep = Bioworks::Pep.new
    testing = ['005a, 1131', '005b, 1131 - 1133', '1131', '1131 - 1133']
    answers = [%w(005a 1131 1131), %w(005b 1131 1133), [nil, '1131', '1131'], [nil, '1131', '1133']]
    testing.zip(answers) do |ar|
      ans = pep.class.extract_file_info(ar[0])
      ans.join(" ").should == ar[1].join(" ") 
    end
  end

end


