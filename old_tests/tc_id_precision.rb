
require 'test/unit'
require File.dirname(File.expand_path(__FILE__)) + '/load_bin_path'

class IDPrecisionTest < Test::Unit::TestCase

  def initialize(arg)
    super(arg)
    @tfiles = File.dirname(__FILE__) + '/tfiles/'
    @tf_bioworks_inv_xml = @tfiles + "bioworks_with_INV_small.xml" 
    @tf_bioworks_shuff = @tfiles + "bioworks_with_SHUFF_small.xml"
    @cmd = "ruby -I#{File.join(File.dirname(__FILE__), "..", "lib")} -S id_precision.rb "
  end

  def test_usage
    #puts "RUNNING: #{@cmd}"
    assert_match(/usage:/, `#{@cmd}`)
  end

  ## freeze the output
  def test_basic
    cmd = "#{@cmd} INV_ #{@tf_bioworks_inv_xml}"
    #puts "RUNNING: #{cmd}"
    reply = `#{cmd}`
    string =<<END
#  NH = number of hits
#  TP = true positives
#  FP = false positives
#  PR = precision = TP/(TP+FP)
PepProts: NH,PepProts: PR,SeqCharge: NH,SeqCharge: PR,Scan(TopHit): NH,Scan(TopHit): PR,Scan(Top10): NH,Scan(Top10): PR,ScanCharge(TopHit): NH,ScanCharge(TopHit): PR,ScanCharge(Top10): NH,ScanCharge(Top10): PR
75, 1.0, 37, 1.0, 75, 1.0, 75, 1.0, 75, 1.0, 75, 1.0
95, 1.0, 49, 1.0, 95, 1.0, 95, 1.0, 95, 1.0, 95, 1.0
155, 1.0, 67, 1.0, 123, 1.0, 155, 1.0, 125, 1.0, 155, 1.0
186, 1.0, 85, 1.0, 154, 1.0, 186, 1.0, 156, 1.0, 186, 1.0
196, 1.0, 90, 1.0, 161, 1.0, 196, 1.0, 163, 1.0, 196, 1.0
214, 1.0, 94, 1.0, 168, 1.0, 214, 1.0, 170, 1.0, 214, 1.0
215, 1.0, 95, 1.0, 169, 1.0, 215, 1.0, 171, 1.0, 215, 1.0
217, 0.995391705069124, 97, 0.989690721649485, 171, 0.994152046783626, 217, 0.995391705069124, 173, 0.994219653179191, 217, 0.995391705069124
219, 0.995433789954338, 99, 0.98989898989899, 172, 0.994186046511628, 219, 0.995433789954338, 175, 0.994285714285714, 219, 0.995433789954338
227, 0.995594713656388, 106, 0.990566037735849, 180, 0.994444444444444, 227, 0.995594713656388, 183, 0.994535519125683, 227, 0.995594713656388
228, 0.995614035087719, 107, 0.990654205607477, 181, 0.994475138121547, 228, 0.995614035087719, 184, 0.994565217391304, 228, 0.995614035087719
229, 0.991266375545852, 108, 0.981481481481482, 182, 0.989010989010989, 229, 0.991266375545852, 185, 0.989189189189189, 229, 0.991266375545852
END

    # This was the result we were getting before first hashing on protein
    # sequences and doing uniqe peptide hits.  It is very similar ( but not
    # exactly the same) to what we are doing now).  Must have something to do
    # with the way things are hashed out.
    before_doing_uniq_peptides=<<END
#  NH = number of hits
#  TP = true positives
#  FP = false positives
#  PR = precision = TP/(TP+FP)
PepProts: NH,PepProts: PR,SeqCharge: NH,SeqCharge: PR,Scan(TopHit): NH,Scan(TopHit): PR,Scan(Top10): NH,Scan(Top10): PR,ScanCharge(TopHit): NH,ScanCharge(TopHit): PR,ScanCharge(Top10): NH,ScanCharge(Top10): PR
75, 1.0, 37, 1.0, 75, 1.0, 75, 1.0, 75, 1.0, 75, 1.0
95, 1.0, 49, 1.0, 95, 1.0, 95, 1.0, 95, 1.0, 95, 1.0
125, 1.0, 67, 1.0, 123, 1.0, 125, 1.0, 125, 1.0, 125, 1.0
155, 1.0, 85, 1.0, 154, 1.0, 155, 1.0, 156, 1.0, 155, 1.0
186, 1.0, 90, 1.0, 161, 1.0, 186, 1.0, 163, 1.0, 186, 1.0
193, 1.0, 94, 1.0, 168, 1.0, 193, 1.0, 170, 1.0, 193, 1.0
204, 1.0, 95, 1.0, 169, 1.0, 204, 1.0, 171, 1.0, 204, 1.0
212, 1.0, 97, 0.989690721649485, 171, 0.994152046783626, 212, 1.0, 173, 0.994219653179191, 212, 1.0
214, 0.995327102803738, 99, 0.98989898989899, 172, 0.994186046511628, 214, 0.995327102803738, 175, 0.994285714285714, 214, 0.995327102803738
216, 0.99537037037037, 106, 0.990566037735849, 180, 0.994444444444444, 216, 0.99537037037037, 183, 0.994535519125683, 216, 0.99537037037037
227, 0.995594713656388, 107, 0.990654205607477, 181, 0.994475138121547, 227, 0.995594713656388, 184, 0.994565217391304, 227, 0.995594713656388
228, 0.995614035087719, 108, 0.981481481481482, 182, 0.989010989010989, 228, 0.995614035087719, 185, 0.989189189189189, 228, 0.995614035087719
229, 0.991266375545852, , , , , 229, 0.991266375545852, , , 229, 0.991266375545852
END
    assert_equal(string, reply)
  end

  def test_basic_with_area
    cmd = "#{@cmd} INV_ #{@tf_bioworks_inv_xml} -a"
    #puts "RUNNING: #{cmd}"
    reply = `#{cmd}`
    # This is what we were getting before hashing for uniqe peptides
    # It is very similar (but not identical to previous output)
    string =<<END
Filename PepProts SeqCharge Scan(TopHit) Scan(Top10) ScanCharge(TopHit) ScanCharge(Top10)
./test/tfiles/bioworks_with_INV_small.xml 228.925377117814 107.877585995136 181.929045912105 228.925377117814 184.924437525838 228.925377117814
END

    string =<<NEWEND
Filename PepProts SeqCharge Scan(TopHit) Scan(Top10) ScanCharge(TopHit) ScanCharge(Top10)
./test/tfiles/bioworks_with_INV_small.xml 228.939375794224 107.877585995136 181.929045912105 228.939375794224 184.924437525838 228.939375794224
NEWEND
    assert_equal(string, reply, "area under the curve")
  end
end
