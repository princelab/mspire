require File.expand_path( File.dirname(__FILE__) + '/../spec_helper' )

require 'spec_id/sqt'
require 'spec_id/srf'

SpecHelperHeaderHash = {
  'SQTGenerator' => 'mspire',
  'SQTGeneratorVersion' => String,
  'Database' => 'C:\\Xcalibur\\database\\ecoli_K12_ncbi_20060321.fasta',
  'FragmentMasses' => 'AVG',
  'PrecursorMasses' => 'AVG',
  'StartTime' => nil, 
  'Alg-MSModel' => 'LCQ Deca XP',
  'Alg-PreMassUnits' => 'amu',
  'DBLocusCount' => '4237',
  'Alg-FragMassTol' => '1.0000',
  'Alg-PreMassTol' => '1.4000',
  'Alg-IonSeries' => '0 1 1 0.0 1.0 0.0 0.0 0.0 0.0 0.0 1.0 0.0',
  'Alg-Enzyme' => 'Trypsin(KR/P) (2)',
  'Comment' => ['Created from Bioworks .srf file'],
  'StaticMod' => ['C=160.1901','Cterm=10.1230','E=161.4455'],
  'DynamicMod' => ['STY*=+79.97990', 'M#=+14.02660'],
}

SpecHelperOtherLines =<<END
S	2	2	1	0.0	VELA	391.04541015625	3021.5419921875	0.0	0
S	3	3	1	0.0	VELA	446.009033203125	1743.96911621094	0.0	122
M	1	1	445.5769264522	0.0	0.245620265603065	16.6666660308838	1	6	R.SNSK.S	U
L	gi|16128266|ref|NP_414815.1|
END

SpecHelperOtherLinesEnd =<<END
L	gi|90111093|ref|NP_414704.4|
M	10	17	1298.5350544522	0.235343858599663	0.823222815990448	151.717300415039	12	54	K.LQKIITNSY*K	U
L	gi|90111124|ref|NP_414904.2|
END

describe 'converting a large srf to sqt' do
  def del(file)
    if File.exist?(file)
      File.unlink(file)
    end
  end

  # returns true or false
  def header_hash_match(header_lines, hash)
    header_lines.all? do |line|
      (h, k, v) = line.chomp.split("\t")
      if hash[k].is_a? Array
        if hash[k].include?(v) 
          true
        else
          puts "FAILED: "
          p k
          p v
          p hash[k]
          false
        end
      elsif hash[k] == String
        v.is_a?(String)
      else
        if v == hash[k]
          true
        else
          puts "FAILED: "
          p k
          p v
          p hash[k]
          false
        end
      end
    end
  end

  spec_large do
    before(:all) do
      @file = Tfiles_l + '/opd1_static_diff_mods/000.srf'
      @output = Tfiles_l + '/opd1_static_diff_mods/000.sqt.tmp'
      @srf = SRF.new(@file)
      @original_db_filename = @srf.header.db_filename
    end
    it 'converts without bothering with the database' do
      @srf.to_sqt(@output)
      @output.exist_as_a_file?.should be_true
      lines = File.readlines(@output)
      lines.size.should == 80910
      header_lines = lines.grep(/^H/)
      (header_lines.size > 10).should be_true
      header_hash_match(header_lines, SpecHelperHeaderHash).should be_true
      other_lines = lines.grep(/^[^H]/)
      other_lines[0,4].join('').should == SpecHelperOtherLines
      other_lines[-3,3].join('').should == SpecHelperOtherLinesEnd
      del(@output)
    end
    it 'warns if the db path is incorrect and we want to update db info' do
      # requires some knowledge of how the database file is extracted
      # internally
      wacky_path = '/not/a/real/path/wacky.fasta'
      @srf.header.db_filename = wacky_path
      my_error_string = ''
      StringIO.open(my_error_string, 'w') do |strio|
        $stderr = strio
        @srf.to_sqt(@output, :db_info => true)
      end
      my_error_string.should include(wacky_path)
      @srf.header.db_filename = @original_db_filename
      $stderr = STDERR
      @output.exist_as_a_file?.should be_true
      IO.readlines(@output).size.should == 80910
      del(@output)
    end
    it 'can get db info with correct path' do
      @srf.to_sqt(@output, :db_info => true, :new_db_path => Tfiles_l + '/opd1_2runs_2mods/sequest33')
      @output.exist_as_a_file?.should be_true
      lines = IO.readlines(@output)
      has_md5 = lines.any? do |line|
        line =~ /DBMD5Sum\s+202b1d95e91f2da30191174a7f13a04e/
      end
      has_md5.should be_true

      has_seq_len = lines.any? do |line|
        # frozen
        line =~ /DBSeqLength\s+1342842/
      end
      has_seq_len.should be_true
      lines.size.should == 80912
      del(@output)
    end
    it 'can update the Database' do
      @srf.to_sqt(@output, :new_db_path => Tfiles_l + '/opd1_2runs_2mods/sequest33', :update_db_path => true)
      regexp = Regexp.new("Database\t/.*/opd1_2runs_2mods/sequest33/ecoli_K12_ncbi_20060321.fasta")
      updated_db = IO.readlines(@output).any? do |line|
        line =~ regexp
      end
      updated_db.should be_true
      del(@output)
    end
  end
end

HeaderHash = {}
header_doublets = [
  %w(SQTGenerator	mspire),
  %w(SQTGeneratorVersion	0.3.1),
  %w(Database	C:\Xcalibur\database\ecoli_K12_ncbi_20060321.fasta),
  %w(FragmentMasses	AVG),
  %w(PrecursorMasses	AVG),
  ['StartTime', ''],
  ['Alg-MSModel', 'LCQ Deca XP'],
  %w(DBLocusCount	4237),
  %w(Alg-FragMassTol	1.0000),
  %w(Alg-PreMassTol	25.0000),
  ['Alg-IonSeries', '0 1 1 0.0 1.0 0.0 0.0 0.0 0.0 0.0 1.0 0.0'],
  %w(Alg-PreMassUnits	ppm),
  ['Alg-Enzyme', 'Trypsin(KR/P) (2)'],

  ['Comment', ['ultra small file created for testing', 'Created from Bioworks .srf file']],
  ['DynamicMod', ['M*=+15.99940', 'STY#=+79.97990']],
  ['StaticMod', []],
].each do |double|
  HeaderHash[double[0]] = double[1]
end

TestSpectra = {
  :first => { :first_scan=>2, :last_scan=>2, :charge=>1, :time_to_process=>0.0, :node=>"TESLA", :mh=>390.92919921875, :total_intensity=>2653.90307617188, :lowest_sp=>0.0, :num_matched_peptides=>0, :matches=>[]},
  :last => { :first_scan=>27, :last_scan=>27, :charge=>1, :time_to_process=>0.0, :node=>"TESLA", :mh=>393.008056640625, :total_intensity=>2896.16967773438, :lowest_sp=>0.0, :num_matched_peptides=>0, :matches=>[] },
  :seventeenth => {:first_scan=>23, :last_scan=>23, :charge=>1, :time_to_process=>0.0, :node=>"TESLA", :mh=>1022.10571289062, :total_intensity=>3637.86059570312, :lowest_sp=>0.0, :num_matched_peptides=>41},
  :first_match_17 => { :rxcorr=>1, :rsp=>5, :mh=>1022.11662242, :deltacn_orig=>0.0, :xcorr=>0.725152492523193, :sp=>73.9527359008789, :ions_matched=>6, :ions_total=>24, :sequence=>"-.MGT#TTM*GVK.L", :manual_validation_status=>"U", :first_scan=>23, :last_scan=>23, :charge=>1, :deltacn=>0.0672458708286285, :aaseq => 'MGTTTMGVK' },
  :last_match_17 => {:rxcorr=>10, :rsp=>16, :mh=>1022.09807242, :deltacn_orig=>0.398330867290497, :xcorr=>0.436301857233047, :sp=>49.735767364502, :ions_matched=>5, :ions_total=>21, :sequence=>"-.MRT#TSFAK.V", :manual_validation_status=>"U", :first_scan=>23, :last_scan=>23, :charge=>1, :deltacn=>1.1, :aaseq => 'MRTTSFAK'},
  :last_match_17_last_loci => {:reference =>'gi|16129390|ref|NP_415948.1|', :first_entry =>'gi|16129390|ref|NP_415948.1|', :locus =>'gi|16129390|ref|NP_415948.1|', :description => 'Fake description' }
}


describe SQT, ": reading a small sqt file" do
  before(:each) do
    file = Tfiles + '/small.sqt'
    file.exist_as_a_file?.should be_true
    @sqt = SQT.new(file)
  end

  it 'can access header entries like a hash' do
    header = @sqt.header
    HeaderHash.each do |k,v|
      header[k].should == v
    end
  end

  it 'can access header entries with methods' do
    header = @sqt.header
    # for example:
    header.database.should == HeaderHash['Database']
    # all working:
    HeaderHash.each do |k,v|
      header.send(SQT::Header::KeysToAtts[k]).should == v
    end

  end

  it 'has spectra, matches, and loci' do
    svt = @sqt.spectra[16]
    reply = {:first => @sqt.spectra.first, :last => @sqt.spectra.last, :seventeenth => svt, :first_match_17 => svt.matches.first, :last_match_17 => svt.matches.last, :last_match_17_last_loci => svt.matches.last.loci.last}
    [:first, :last, :seventeenth, :first_match_17, :last_match_17, :last_match_17_last_loci].each do |key|
      TestSpectra[key].each do |k,v|
        if v.is_a? Float
          reply[key].send(k).should be_close(v, 0.0000000001)
        else
          reply[key].send(k).should == v
        end
      end
    end
    @sqt.spectra[16].matches.first.loci.size.should == 1
    @sqt.spectra[16].matches.last.loci.size.should == 1
  end

end

describe SQTGroup, ': acting as a SpecID on large files' do
  spec_large do 
    before(:each) do
      file1 = Tfiles_l + '/opd1_2runs_2mods/sequest33/020.sqt'
      file2 = Tfiles_l + '/opd1_2runs_2mods/sequest33/040.sqt'
      file1.exist_as_a_file?.should be_true
      file2.exist_as_a_file?.should be_true
      @sqg = SQTGroup.new([file1, file2])
    end

    it 'has peptide hits' do
      peps = @sqg.peps
      peps.size.should == 38512  # frozen
      # first hit in 020
      peps.first.sequence.should == 'R.Y#RLGGS#T#K.K'
      peps.first.base_name.should == '020'
      # last hit in 040
      peps.last.sequence.should == 'K.NQTNNRFK.T'
      peps.last.base_name.should == '040'
    end

    it 'has prots' do
      ## FROZEN:
      @sqg.prots.size.should == 3994
      sorted = @sqg.prots.sort_by {|v| v.reference }
      sorted.first.reference.should == 'gi|16127996|ref|NP_414543.1|'
      sorted.first.peps.size.should == 33
    end
  end
end
