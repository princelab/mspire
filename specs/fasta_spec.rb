require File.expand_path( File.dirname(__FILE__) + '/spec_helper' )

require 'fasta'

Filestring = ">gi|P1
AMKRGAN
>gi|P2
CRGATKKTAGRPMEK
>gi|P3
PEPTIDE
"

class Fasta
  def proteins?
    (@prots.size > 0) and
    @prots.first.is_a? Fasta::Prot
  end
end

describe Fasta do

  it 'can be set from a string' do
    obj = Fasta.from_string(Filestring)
    obj.is_a?(Fasta).should be_true
    obj.proteins?.should be_true
    obj.size.should == 3
    matches_filestring(obj)
  end

  # given a fasta obj, asks if it matches filestring
  def matches_filestring(obj)
    heads = %w(>gi|P1 >gi|P2 >gi|P3)
    seqs = %w(AMKRGAN CRGATKKTAGRPMEK PEPTIDE)
    obj.zip(heads, seqs) do |prot, head, seq|
      prot.header.should == head
      prot.aaseq.should == seq
    end
  end

end

describe Fasta::Prot do

  it 'can extract a gi code out of ncbi sequences' do
    gis = ['>gi|7427923|pir||PHRBG glycogen phosphorylase (EC 2.4.1.1), muscle - rabbit', '>sp|lollygag|helloyou', '>only has one bar | and thats it', 'notme|me|nome', '>lots|an|lots|of|bars|heehee']
    answ = ['7427923', 'lollygag', nil, 'me','an']
    actual = gis.map do |head|
      Fasta::Prot.new(head).gi
    end
    actual.should == answ
  end
end

=begin

require File.dirname(File.expand_path(__FILE__)) + '/load_bin_path'
require 'test/unit'
require 'fasta'
require 'assert_files'
require 'sample_enzyme'
require 'set'


module Test::Unit::Assertions
  @@file_display_length = 10000
end

class FastaTest < Test::Unit::TestCase
  NODELETE = false

  def initialize(arg)
    super(arg)

    @cat_shuffle_postfix = Fasta::CAT_SHUFF_FILE_POSTFIX
    @connector = Fasta::FILE_CONNECTOR
    @shuff_prefix = Fasta::SHUFF_PREFIX
    @inv_prefix = Fasta::SHUFF_PREFIX
    @shuff_ext = Fasta::SHUFF_FILE_POSTFIX
    @inv_ext = Fasta::INV_FILE_POSTFIX

    @tfiles = File.dirname(__FILE__) + '/tfiles/'
    @base_cmd = "ruby -I #{File.join(File.dirname(__FILE__), "..", "lib")} -S "
    @fasta_mod_cmd = @base_cmd + "fasta_mod.rb "
    @fasta_cat_mod_cmd = @base_cmd + "fasta_cat_mod.rb "
    @fasta_cat_cmd = @base_cmd + "fasta_cat.rb "
    @sf = @tfiles + "small.fasta"
    @sf_shuffle = @tfiles + "small#{@shuff_ext}.fasta"
    @sf_invert = @tfiles + "small#{@inv_ext}.fasta"
    @sf_cat = @tfiles + "small__small_SHUFF.fasta"
    @sf_cat_mod = @tfiles + "small#{@cat_shuffle_postfix}.fasta"
    @mf = @tfiles + "messups.fasta"
  end

  def test_read_file
    obj = Fasta.new.read_file(@sf)
    @tmpfile = @tfiles + "tmp.tmp"
    obj.write_file(@tmpfile)
    assert_not_equal_file_content(@tmpfile, @sf)
    obj2 = Fasta.new.read_file(@tmpfile)
    File.unlink(@tmpfile)
    assert_equal(obj, obj2)
  end

  def test_cat
    obj = Fasta.new.read_file(@sf)
    first_size = obj.prots.size
    obj << obj
    assert_equal(2, obj.prots.size/first_size)
  end

  def test_dup
    obj = Fasta.new.read_file(@sf)
    objd = obj.dup
    obj_prots = obj.prots
    objd.prots.each do |prot|
      assert(obj_prots.include?(prot))
    end
  end

  def test_prefix_extension
    assert('f_howdy.ext', Fasta.prefix_extension('f.ext', '_howdy'))
    assert('f.ext_howdy.ext', Fasta.prefix_extension('f.ext.ext', '_howdy'))
  end

  def test_cat_filenames
    assert('f1f2.ext1', Fasta.cat_filenames(['f1.ext1', 'f2.ext2']))
    assert('f1__f2.ext1', Fasta.cat_filenames(['f1.ext1', 'f2.ext2'], '__'))
  end

  def test_mod
    ## Testing shuffle:
    `#{@fasta_mod_cmd + 'shuffle ' + @sf}`
    assert(File.exist?(@sf_shuffle), "output file #{@sf_shuffle} exists")
    ob1 = Fasta.new.read_file(@sf)
    ob2 = Fasta.new.read_file(@sf_shuffle)
    assert_not_equal_file_content(@sf_shuffle, @sf)
    File.unlink @sf_shuffle
    assert(_same_headers?(ob1,ob2))
    assert(_are_shuffled?(ob1,ob2))

    ## Testing invert:
    `#{@fasta_mod_cmd + 'invert ' + @sf}`
    assert(File.exist?(@sf_invert), "output file #{@sf_invert} exists")
    ob1 = Fasta.new.read_file(@sf)
    ob2 = Fasta.new.read_file(@sf_invert)
    assert_not_equal_file_content(@sf_invert, @sf)
    File.unlink(@sf_invert)
    assert(_same_headers?(ob1,ob2))
    assert(_are_inverted?(ob1,ob2))

    ## Testing prefix
    #puts "#{@fasta_mod_cmd + '-p _HELLO_ invert ' + @sf}"
    `#{@fasta_mod_cmd + 'invert -p _HELLO_ ' + @sf}` # NOT WORKING!
    assert(File.exist?(@sf_invert), "output file #{@sf_invert} exists")
    ob1 = Fasta.new.read_file(@sf)
    ob2 = Fasta.new.read_file(@sf_invert)
    assert(_are_inverted?(ob1,ob2))
    assert_equal(ob1.prots.size, IO.read(@sf_invert).scan(/>_HELLO_/).size)
    File.unlink(@sf_invert)
  end

  ## IN PROGRESS:
  def Xtest_cat_mod

    assert(File.exist?(@sf), "prerequisite for cat tests")

    ## Single file to cat shuffle test
    puts `#{@fcat_mod_cmd + @sf}`
    assert(File.exist?(@sf_cat_single), "output file exists")
    ob1 = Fasta.new.read_file(@sf)
    ob2 = Fasta.new.read_file(@sf_cat_single)
    assert_equal(2, ob2.prots.size/ob1.prots.size)
    assert_equal(ob1.prots, ob2.prots[0, (ob1.prots.size)])
    assert_not_equal(ob1.prots, ob2.prots[(ob1.prots.size)..-1])
    File.unlink @sf_cat_single
  end

  ## IN PROGRESS:
  def Xtest_cat

    ## Concatenate files test:
    puts `#{@cat_cmd + @sf} -p ,#{@shuff_prefix} #{@sfn}`
    assert(File.exist?(@sf_cat), "output file #{@sf_cat} exists")
    ob1 = Fasta.new.read_file(@sf)
    ob2 = Fasta.new.read_file(@sfn)
    ob3 = Fasta.new.read_file(@sf_cat)
    assert_not_equal_file_content(@sf_cat, @sf)
    assert_not_equal_file_content(@sf_cat, @sfn)
    [@sfn,@sf_cat].each { |f| File.unlink f }

    ob2.header_prefix!(@shuff_prefix)
    ob3_prots = ob3.prots
    [ob1, ob2].each do |ob|
      ob.prots.each do |prot|
        unless ob3_prots.include? prot
          p prot
          flunk "protein not found in cat version"
        end
      end
    end


    # test catenation
    sfci = "small_CAT_INV.fasta"
    cat_inverted = @tfiles + sfci
    iccmd = @base_cmd + "fasta_cat_inverse.rb "
    cmd = iccmd + @sf
    puts `#{cmd}`
    assert(File.exist?(cat_inverted), "file #{cat_inverted} exists")

    norm = Fasta.new.read_file(@sf)
    cat_inv = Fasta.new.read_file(cat_inverted)
    File.unlink(cat_inverted)

    num_prots = norm.prots.size
    cat_norm_prots = cat_inv.prots[0, num_prots]
    cat_inv_prots = cat_inv.prots[num_prots..-1]
    norm.prots.each_with_index do |prot,i|
      assert_equal(prot.header, cat_norm_prots[i].header)
      assert_not_equal(prot.header, cat_inv_prots[i].header)
      assert_equal(prot.aaseq, cat_norm_prots[i].aaseq) 
      assert_equal(prot.aaseq.reverse!, cat_inv_prots[i].aaseq) 
    end
  end

  def test_invert_tryptic_peptides
    # FOR INDIVIDUAL PROTEINS:
    seq = 'ABCKCDERDEKDGEKWXYRRKDER'
    # tryptic = ABCK, CDER, DEK, DGEK, WXYR, R, K, DER
    tryp = SampleEnzyme.tryptic(seq)
    reverse_tryptic = %w(CBAK EDCR EDK EGDK YXWR R K EDR)
    prot = Fasta::Prot.new(nil, seq)
    prot.invert_tryptic_peptides!
    assert_equal(reverse_tryptic.join(''), prot.aaseq, "reversing tryptic peptides")

    seq = 'XYRABCD'
    prot = Fasta::Prot.new(nil, seq)
    prot.invert_tryptic_peptides!
    assert_equal('YXRDCBA', prot.aaseq, 'last peptide treated special')

    seq = 'XYRPABCD'
    prot = Fasta::Prot.new(nil, seq)
    prot.invert_tryptic_peptides!
    assert_equal('DCBAPRYX', prot.aaseq, 'with a proline')
    
  end

  def test_fraction_of_prots
    peps = [['>silly1', "PEPTIDE"], ['>silly2', "ANOTHER"], ['>silly3', "AGAIN"], ['>silly4', "LARMA"]]
    prots = peps.map do |header, seq|
      Fasta::Prot.new(header, seq)
    end
    f = Fasta.new(prots)
    # simple:
    n = f.fraction_of_prots(1.0)
    assert_equal(f.prots.map{|v| v.header }.to_set, n.prots.map{|v| v.header }.to_set, "same headers")
    assert_equal(f.prots.map{|v| v.aaseq }.to_set, n.prots.map{|v| v.aaseq }.to_set, "same aaseqs")

    pre = proc {|cnt| "SHUFF_f#{cnt}_" }
    # test prefix
    n = f.fraction_of_prots(1.0, pre)
    n.prots.each do |prot|
      assert_match(/^>SHUFF_f0_/, prot.header, "contains new prefix")
    end

    # smaller
    n = f.fraction_of_prots(0.75, pre)
    assert_equal(3, n.prots.size, "correct number of proteins")
    # bigger
    n = f.fraction_of_prots(2.5, pre)
    assert_equal(10, n.prots.size, "correct number of proteins")
    n.prots[0..3].each {|prt| assert_match(/^>SHUFF_f0_/, prt.header ) }
    n.prots[4..7].each {|prt| assert_match(/^>SHUFF_f1_/, prt.header ) }
    n.prots[8..9].each {|prt| assert_match(/^>SHUFF_f2_/, prt.header ) }
    # crazy
    n = f.fraction_of_prots(1.33, pre)
    assert_equal(6, n.prots.size, "correct number of proteins")
  end

  def test_inverted_tryptic_peptides_for_file
    # for a file:
    tmpfile = @tfiles + "fasta.tmp"
    fasta = Fasta.new.read_file(@sf)
    fasta.aaseq_invert_tryptic_peptides!
    fasta.write_file(tmpfile)
    lines = IO.readlines(tmpfile)
    #normal = 'MKRISTTITTTITITTGNGAG'
    inverted_tryptic = 'MKRGAGNGTTITITTTITTSI' ## ?????
    assert_equal(inverted_tryptic, lines[1].chomp)
    #normal =  'MATYLIGDVHGCYDELIALLHKVEFTPGKDTLWLTGDLVARGPGSLDVLRYVKSLGDSVRLVLGNHDLHL
    # LAVFAGISRNKPKDRLTPLLEAPDADELLNWLRRQPLLQIDEEKKLVMAHAGITPQWDLQTAKECARDVE
    # AVLSSDSYPFFLDAMYGDMPNNWSPELRGLGRLRFITNAFTRMRFCFPNGQLDMYSKESPEEAPAPLKPW
    # FAIPGPVAEEYSIAFGHWASLEGKGTPEGIYALDTGCCWGGTLTCLRWEDKQYFVQPSNRHKDLGEAAAS'
    inverted_tryptic = 'HLLAILEDYCGHVDGILYTAMKGPTFEVKAVLDGTLWLTDRLVDLSGPGRVYKVSDGLSRSIGAFVALLHLDHNGLVLRPKNKDRLWNLLEDADPAELLPTLRREEDIQLLPQKKATQLDWQPTIGAHAMVLKACERLEPSWNNPMDGYMADLFFPYSDSSLVAEVDRGLGRLRTFANTIFRMRSYMDLQGNPFCFKGELSAWHGFAISYEEAVPGPIAFWPKLPAPAEEPSEKLCTLTGGWCCGTDLAYIGEPTGRDEWKNSPQVFYQRHKSAAAEGLD'
    assert_equal(inverted_tryptic, lines[-1].chomp)
    File.unlink(tmpfile) unless NODELETE
  end

  

  ## HELPER ASSERTIONS:

  def _are_inverted?(obj1, obj2) 
    obj2_prots = obj2.prots
    obj1.prots.each_with_index do |prot,i| 
      if prot.aaseq.reverse != obj2_prots[i].aaseq
        return false
      end
    end
    return true
  end

  def _same_headers?(obj1, obj2)
    obj1.prots.each_with_index do |prot,ind|
      oprot = obj2.prots[ind]
      if prot.header != oprot.header
        return false
      end
    end
    return true
  end

  # true if all prot AA seq's are the same
  def _same_aaseqs?(obj1, obj2)
    obj2_prots = obj2.prots
    obj1.prots.each_with_index do |prot,i|
      if prot.aaseq != obj2_prots[i].aaseq
        return false
      end
    end
    return true
  end

  # for two parallel fasta objects, determines if the list of proteins 
  # are shuffled by examining the proteins and asking of > 4 are different
  # returns true or false
  def _are_shuffled?(obj1, obj2)
    cnt = 0
    obj1.prots.each_with_index do |prot,ind|
      oprot = obj2.prots[ind]
      if prot.header == oprot.header && prot.aaseq != oprot.aaseq
        cnt += 1
      end
    end
    if cnt > 4 
      return true 
    else
      return false
    end
  end

end

=end
