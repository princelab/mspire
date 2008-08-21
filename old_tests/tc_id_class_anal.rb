
require 'test/unit'
require File.dirname(File.expand_path(__FILE__)) + '/load_bin_path'


class IDClassAnalTest < Test::Unit::TestCase

  def initialize(arg)
    super(arg)
    @tfiles = File.dirname(__FILE__) + '/tfiles/'
    @tf_bioworks_esmall_xml = @tfiles + "bioworks_with_INV_small.xml" 
    @tf_bioworks_small_xml = @tfiles + "bioworks_small.xml"
    @tf_bioworks_shuff = @tfiles + "bioworks_with_SHUFF_small.xml"
    @tf_proph_inv = @tfiles + "opd1/opd1_cat_inv_small-prot.xml"
    @cmd = "ruby -I#{File.join(File.dirname(__FILE__), "..", "lib")} -S id_class_anal.rb "
  end

  def test_usage
    assert_match(/usage:/, `#{@cmd}`)
  end

  def test_proph_basic
    output = `#{@cmd} -p INV_ #{@tf_proph_inv}`
    fps = [1.00, 1.00, 0.97]
    tps = [1.00, 1.00, 0.98, 0.97, 0.97, 0.97, 0.97]
    #File.open("tmp.csv","w") do |fh| fh.print output end
    assert 1
  end

  def test_basic
    output = `#{@cmd} -p INV_ #{@tf_bioworks_esmall_xml}`
    exp = [
      [1, 1.0, 0.0],
      [2, 1.0, 0.0],
      [3, 1.0, 0.0],
      [4, 1.0, 0.0],
      [5, 1.0, 0.0],
      [6, 1.0, 0.0],
      [9, 1.0, 0.0],
      [10, 1.0, 0.0],
      [11, 0.909090909090909],
      [12, 0.916666666666667],
      [13, 0.923076923076923],
      [14, 0.928571428571429],
      [15, 0.866666666666667],
    ]
    outarr = output.split($/)
    exp.each_with_index do |line,i|
      outfloats = outarr[i+1].split("\t").collect {|v| v.to_f }
      line.each_with_index do |v,j|
        assert_in_delta(v, outfloats[j], 0.00000000000000001)
      end
    end
  end

  def test_multiple_output
    myplot = 'class_anal.toplot'
    output = `#{@cmd} -j -p INV_,SHUFF_ #{@tf_bioworks_esmall_xml} #{@tf_bioworks_shuff}`
    assert(output.size > 10) ## @TODO: BETTER HERE
    assert(File.exist?(myplot), "file #{myplot} exists")
    File.unlink myplot
  end

  def test_jtplot_output
    myplot = 'class_anal.toplot'
    output = `#{@cmd} -p INV_ -j #{@tf_bioworks_esmall_xml}`
    assert(File.exist?(myplot), "file #{myplot} exists")
    File.unlink myplot
  end
end
