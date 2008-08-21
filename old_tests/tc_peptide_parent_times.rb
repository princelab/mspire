
require 'test/unit'

class PeptideParentTimesTest < Test::Unit::TestCase

  def initialize(arg)
    super(arg)
    @tfiles = "tfiles" # relative test file directory
  end

  def test_blank
    ## need to finish this guy up:
    puts "\nSKIPPING: tests for peptide_parent_times"
  end

  def Xtest_run
    reply = `ruby ../script/peptide_parent_times.rb 1.00 tfiles/yeast_gly_small-prot.xml tfiles/yeast_gly_small.xml tfiles/020a.mzXML.timeIndex`
    #puts reply
    string1 = File.open((@tfiles +'/'+'yeast_gly_small.1.0_1.0_1.0.parentTimes__020a.working')).read
    assert(string1.size > 20)
    string2 = File.open((@tfiles +'/'+'yeast_gly_small.1.0_1.0_1.0.parentTimes__020a')).read
    assert_equal(string1, string2)
    to_delete = %w(yeast_gly_small.xml.seqchargehash yeast_gly_small-prot.xml.1.0_1.0_1.0.protpep yeast_gly_small.1.0_1.0_1.0.parentTimes__020a)
    with_dir = to_delete.collect { |f| @tfiles + '/' + f }
    with_dir.each { |f| File.unlink f }
  end
end
