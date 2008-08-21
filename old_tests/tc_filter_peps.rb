

require 'test/unit'

class TestFiltering < Test::Unit::TestCase
  ROOT_DIR = File.join(File.dirname(__FILE__), '..')

  def test_filter_results
    @tfiles = File.dirname(File.expand_path(__FILE__)) + '/tfiles/'
    @bfile = @tfiles + "bioworks_with_SHUFF_small.xml"
    
    cmd_core = "ruby -I #{File.join(ROOT_DIR, 'lib')} #{File.join(ROOT_DIR, 'script', 'filter-peps.rb')} "
    #puts `#{cmd_core}`
    cmd = cmd_core + "SHUFF_ #{@bfile}"
    output = `#{cmd}`
    
    freeze = %{FILENAME\tPepProts\tScanChargeBest\tScanChargeTop10\tScanBest\tScanTop10\tSeqChargeBest\tSeqChargeTop10
TP: #{@tfiles}bioworks_with_SHUFF_small.xml\t3\t3\t3\t3\t3\t3\t3
FP: #{@tfiles}bioworks_with_SHUFF_small.xml\t3\t3\t3\t3\t3\t2\t3
DIFF: #{@tfiles}bioworks_with_SHUFF_small.xml\t0\t0\t0\t0\t0\t1\t0
}
    assert_equal(freeze, output)




    cmd = cmd_core + "SHUFF_ #{@bfile} -1 1.0 -2 2.0 -3 3.0"
    output = `#{cmd}`
    
    freeze = %{FILENAME\tPepProts\tScanChargeBest\tScanChargeTop10\tScanBest\tScanTop10\tSeqChargeBest\tSeqChargeTop10
TP: #{@tfiles}bioworks_with_SHUFF_small.xml\t3\t3\t3\t3\t3\t3\t3
FP: #{@tfiles}bioworks_with_SHUFF_small.xml\t4\t4\t4\t4\t4\t3\t4
DIFF: #{@tfiles}bioworks_with_SHUFF_small.xml\t-1\t-1\t-1\t-1\t-1\t0\t-1
}
    assert_equal(freeze, output)



  end






end
