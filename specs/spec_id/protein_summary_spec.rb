require File.expand_path( File.dirname(__FILE__) + '/../spec_helper' )
require 'spec_id/protein_summary'

xdescribe ProteinSummary do

  before(:all) do
    @tf_proph = Tfiles_l + "/opd1/000_020-prot.xml"
    @tf_summary = Tfiles_l + "/opd1/000_020-prot.summary.html"
    @tf_bioworks_small = Tfiles + '/bioworks_small.xml'
    @tf_bioworks_small_summary_html = Tfiles + '/bioworks_small.summary.html'
    @tf_proph_cat_inv =  Tfiles + '/opd1/opd1_cat_inv_small-prot.xml'
    @tf_proph_cat_inv_summary_html = Tfiles + '/opd1/opd1_cat_inv_small-prot.summary.html'
    @tf_proph_cat_inv_summary_png = Tfiles + '/opd1/opd1_cat_inv_small-prot.summary.png'
    @tf_peptide_count = Tfiles + "/peptide_counts.tmp.txt"
    @no_delete = false
  end

  spec_large do
    it 'does basic summary on prophet file' do
      runit "-c 5.0 #{@tf_proph}"
      @tf_summary.exist_as_a_file?.should be_true
      string = IO.read(@tf_summary)
      string.should =~ /gi\|16132176\|ref\|NP_418775\.1\|/
      string.should =~ /16132176/
      File.unlink(@tf_summary) unless @no_delete
    end
  end

  it 'does basic summary on bioworks.xml file' do
    runit "#{@tf_bioworks_small}"
    @tf_bioworks_small_summary_html.exist_as_a_file?.should be_true
    File.unlink @tf_bioworks_small_summary_html unless @no_delete
    # @TODO: need to freeze the output here
  end


  it 'calculates precision values with bioworks files' do
    ## Could reimplement a separate file approach?
    #reply = `#{@cmd} -f #{@tf_bioworks_small} #{@tf_bioworks_small} --precision`
    runit "#{@tf_bioworks_small} --precision"
    IO.read(@tf_bioworks_small_summary_html).should =~ /# hits.*106/m
    # should add more tests here...
    @tf_bioworks_small_summary_html.exist_as_a_file?.should be_true
    File.unlink @tf_bioworks_small_summary_html unless @no_delete
  end

  it 'calculates precision values with prophet files' do
    runit "#{@tf_proph_cat_inv} -f INV_ --prefix --precision"
    html =  IO.read(@tf_proph_cat_inv_summary_html)
    html.should =~ /# hits/
    html.should =~ /2.*0\.0000/m
    html.should =~ /3.*0\.3333/m
    html.should =~ /7.*0\.5714/m

    File.unlink @tf_proph_cat_inv_summary_html unless @no_delete
    File.unlink @tf_proph_cat_inv_summary_png unless @no_delete
  end

  spec_large do
    it 'gives correct peptide counts' do
      runit "-c 5.0 #{@tf_proph} --peptide_count #{@tf_peptide_count}"
      @tf_peptide_count.exist_as_a_file?.should be_true
      file = IO.read(@tf_peptide_count)
      file.should include("gi|16132176|ref|NP_418775.1|\t2")
      file.should include("gi|16131996|ref|NP_418595.1|\t1")
      file.should include("gi|16131692|ref|NP_418288.1|\t4")
      File.unlink @tf_peptide_count unless @no_delete
    end
  end

  def runit(string_or_args)
    args = if string_or_args.is_a? String
             string_or_args.split(/\s+/)
           else
             string_or_args
           end
    ProteinSummary.new.create_from_command_line_args(args) 
  end


  end


=begin

require 'test/unit'
require 'spec_id/protein_summary'
require File.dirname(__FILE__) + '/test_helper'



class ProphProtSummaryTest < Test::Unit::TestCase

  NODELETE = false

  def initialize(arg)
    super(arg)
    @tfiles = File.dirname(__FILE__) + '/tfiles/'
    @tfiles_l = File.dirname(__FILE__) + '/tfiles_large/'
    @tf_proph = @tfiles_l + "opd1/000_020-prot.xml"
    @tf_summary = @tfiles_l + "opd1/000_020-prot.summary.html"
    @tf_bioworks_small = @tfiles + 'bioworks_small.xml'
    @tf_bioworks_small_summary_html = @tfiles + 'bioworks_small.summary.html'
    @tf_proph_cat_inv =  @tfiles + 'opd1/opd1_cat_inv_small-prot.xml'
    @tf_proph_cat_inv_summary_html = @tfiles + 'opd1/opd1_cat_inv_small-prot.summary.html'
    @tf_proph_cat_inv_summary_png = @tfiles + 'opd1/opd1_cat_inv_small-prot.summary.png'
    @tf_peptide_count = @tfiles + "peptide_counts.tmp.txt"
  end

  def runit(string_or_args)
    args = if string_or_args.is_a? String
             string_or_args.split(/\s+/)
           else
             string_or_args
           end
    ProteinSummary.new.create_from_command_line_args(args) 
  end

 
  def test_usage
    output = capture_stdout {
      runit('')
    }
    assert_match(/usage:/, output)
  end

  def test_proph_basic
    if File.exist? @tfiles_l
      runit "-c 5.0 #{@tf_proph}"
      ProteinSummary.new.create_from_command_line_args([@tf_proph, '-c', '5.0'])
      assert(File.exist?(@tf_summary), "file #{@tf_summary} exists")
      string = IO.read(@tf_summary)
      assert_match(/gi\|16132176\|ref\|NP_418775\.1\|/, string)
      assert_match(/16132176/, string)
      File.unlink(@tf_summary) unless NODELETE
    else
      assert_nil( puts("--SKIPPING TEST-- (missing dir: #{@tfiles_l})") )
    end
  end

  def test_bioworks_basic
    runit "#{@tf_bioworks_small}"
    assert(File.exist?(@tf_bioworks_small_summary_html), "file #{@tf_bioworks_small_summary_html} exists")
    File.unlink @tf_bioworks_small_summary_html unless NODELETE

    # @TODO: need to freeze the output here
  end

  def test_bioworks_with_precision
    ## Could reimplement a separate file approach?
    #reply = `#{@cmd} -f #{@tf_bioworks_small} #{@tf_bioworks_small} --precision`
    runit "#{@tf_bioworks_small} --precision"
    assert_match(/# hits.*106/m, IO.read(@tf_bioworks_small_summary_html))
    #assert_match(/False Positive Rate.*: 0.500/, IO.read(@tf_bioworks_small_summary_html))
    #assert_match(/False Positive Rate.*: 0.500/, IO.read(@tf_bioworks_small_summary_html))
    assert(File.exist?(@tf_bioworks_small_summary_html), "file #{@tf_bioworks_small_summary_html} exists")
    File.unlink @tf_bioworks_small_summary_html unless NODELETE
  end

  def test_proph_with_precision
    #puts @cmd
    runit "#{@tf_proph_cat_inv} -f INV_ --prefix --precision"
    html =  IO.read(@tf_proph_cat_inv_summary_html)
    assert_match(/# hits/, html, "in #{@tf_proph_cat_inv_summary_html}")
    assert_match(/2.*0\.0000/m, html, "in #{@tf_proph_cat_inv_summary_html}")
    assert_match(/3.*0\.3333/m, html, "in #{@tf_proph_cat_inv_summary_html}")
    assert_match(/7.*0\.5714/m, html, "in #{@tf_proph_cat_inv_summary_html}")

    File.unlink @tf_proph_cat_inv_summary_html unless NODELETE
    File.unlink @tf_proph_cat_inv_summary_png unless NODELETE
  end

  def test_peptide_count
    if File.exist? @tfiles_l
      runit "-c 5.0 #{@tf_proph} --peptide_count #{@tf_peptide_count}"
      assert(File.exist?(@tf_peptide_count), "file #{@tf_peptide_count} exists")
      file = IO.read(@tf_peptide_count)
      assert_match("gi|16132176|ref|NP_418775.1|\t2", file)
      assert_match("gi|16131996|ref|NP_418595.1|\t1", file)
      assert_match("gi|16131692|ref|NP_418288.1|\t4", file)
      File.unlink @tf_peptide_count unless NODELETE
    else
      assert_nil( puts("--SKIPPING TEST-- (missing dir: #{@tfiles_l})") )
    end
  end

end

=end
