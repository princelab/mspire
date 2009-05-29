
require File.expand_path( File.dirname(__FILE__) + '/../spec_helper' )
require 'ms/msrun'
require 'ostruct'
require 'fileutils'
require 'ms/parser/mzxml'

parsers = %w(AXML LibXML XMLParser Regexp REXML)

XMLStyleParser::Parser_precedence.replace( %w(AXML)  )


shared_examples_for "an msrun with basic, non-spectral information" do
  it 'knows the type and version of file' do
    @run.filetype.should == @info.filetype
    @run.version.should == @info.version
  end

  it 'knows basic run information' do
    @run.scan_count.should == @info.scan_count
    @run.start_time.should == @info.start_time
    @run.end_time.should == @info.end_time
  end

  it 'has all scans' do
    @run.scans.size.should == @info.scan_count
    @run.scans.each_with_index do |sc,i|
      sc.class.should == MS::Scan
    end
  end

  it 'can determine scan counts for any mslevel' do
    @run.scan_counts.class.should == Array
    @run.scan_count(0).should == @info.scan_count0
    @run.scan_count(1).should == @info.scan_count1
    @run.scan_count(2).should == @info.scan_count2
  end

  it 'has correct first two scans and last scan' do
    [0,1,-1].each do |i|
      @info.scans[i].each do |k,v|
        testing = @run.scans[i].send(k)
        if k == :precursor
          testing.mz.should be_close(v.mz, 0.000001)
          if testing.intensity # intensity not guaranteed to exist!
            testing.intensity.should == v.intensity
          end
        else
          @run.scans[i].send(k).should == v
        end
      end
    end
  end
end

shared_examples_for "an msrun with spectrum" do

  it 'has all scans with spectrum data' do
    @run.scans.size.should == @info.scan_count
    @run.scans.each_with_index do |sc,i|
      sc.class.should == MS::Scan
      sc.spectrum.should have_mz_data
      sc.spectrum.should have_intensity_data
    end
  end

  it 'can determine start_and_end_mz' do
    @run.start_and_end_mz(1).should == @info.start_and_end_mz1
    @run.start_and_end_mz(2).should == @info.start_and_end_mz2
  end

  it_should_behave_like "an msrun with basic, non-spectral information"
end

# some xml formats have precursor intensities built in, some do not
shared_examples_for "an msrun with precursor intensities" do 

  it "has correct prec inten for first two scans and last scan" do
    [0,1,-1].each do |i|
      if i == 0
        @run.scans[i].precursor.should be_nil
        next
      end
      expected = @info.scans[i][:precursor]
      @run.scans[i].precursor.mz.should be_close(expected.mz, 0.000001)
      @run.scans[i].precursor.intensity.should == expected.intensity
    end
  end

end

shared_examples_for 'a basic scan info generator' do

  def check_table(table, answer)
    answer.each do |k,v|
      if v == nil
        table[k].should be_nil
      else
        table[k].should be_close(v, 0.000001)
      end
    end
  end
  
  it 'generates precursor_mz_by_scan_num lookup table' do
    ar = @run.precursor_mz_by_scan_num
    check_table(ar, @info.num_to_prec_mz_hash)
  end

  it 'class method -> precursor_mz_by_scan_num (with file)' do
    ar = @info.klass.precursor_mz_by_scan_num(@info.file) 
    check_table(ar, @info.num_to_prec_mz_hash)
  end
end

MzXML_version_1_info = MyOpenStruct.new do |info|
  info.file = Tfiles_l + '/yeast_gly_mzXML/000.mzXML'
  info.klass = MS::MSRun
  info.filetype = :mzxml
  info.version = '1.0'
  info.scan_count = 3748
  #info.scan_counts = [3748, 937, nil] ## need to get ms2
  info.start_time = 0.44
  info.end_time = 5102.55
  info.num_to_prec_mz_hash = {
    0 => nil,
    1 => nil,
    2 => 391.045410,
    3 => 446.009033,
    4 => 1222.033203,
    5 => nil,
    6 => 390.947449,
    3744 => 338.779114,
    3745 => nil,
    3746 => 304.136597,
    3748 => 433.564941,
  }
  info.scans = {}

  info.scans[0] = {
    :num => 1,
    :ms_level => 1,
    :time => 0.440,
  }
  info.scans[1] = {
    :num => 2,
    :ms_level => 2,
    :time => 1.90,
    :precursor => MS::Precursor.new(:mz => 391.045410, :intensity => 6986078.0)
  }
  info.scans[-1] = {
    :num => 3748,
    :ms_level => 2,
    :time => 5102.55,
    :precursor => MS::Precursor.new(:mz => 433.564941, :intensity => 481800.0)
  }
  info.scan_count0 = info.scan_count
  info.scan_count1 = 937
  info.scan_count2 = 2811
  info.start_and_end_mz1 = [300.0, 1500.0]
  info.start_and_end_mz2 = [0.0, 2000.0]
end

describe MS::MSRun, "on mzXML version 1 files (w/o spectra)" do
  spec_large do
    before(:all) do
      @info = MzXML_version_1_info
      start = Time.now
      @run = @info.klass.new(@info.file, :lazy => :no_spectra)
      puts "- read #{File.basename(@info.file)} in #{Time.now - start} seconds" if $specdoc
    end
    it_should_behave_like "an msrun with basic, non-spectral information"
    it_should_behave_like 'a basic scan info generator'
  end
end

describe MS::MSRun, "on mzXML version 1 files (w/spectra)" do
  spec_large do
    before(:all) do
      @info = MzXML_version_1_info
      start = Time.now
      @run = @info.klass.new(@info.file, :lazy => :not)
      puts "- read #{File.basename(@info.file)} in #{Time.now - start} seconds" if $specdoc
    end

    it_should_behave_like "an msrun with spectrum"
    it_should_behave_like "an msrun with precursor intensities"
    it_should_behave_like 'a basic scan info generator'
  end
end

MzXML_version_20_info = MyOpenStruct.new do |info|
  info.file = Tfiles + '/opd1_2runs_2mods/data/020.readw.mzXML'
  info.klass = MS::MSRun
  info.filetype = :mzxml
  info.version = '2.0'
  info.scan_count = 20
  #info.scan_counts = ??
  info.start_time = 0.13
  info.end_time = 27.31
  info.num_to_prec_mz_hash = {
    0 => nil,
    1 => nil,
    2 => 390.9291992,
    3 => 1121.944824,
    4 => 1321.913574,
    17 => nil,
    18 => 308.795959,
    19 => 444.983337,
    20 => 361.671875,
  }
  info.scans = {}
  info.scans[0]= {
    :num => 1,
    :ms_level => 1,
    :time => 0.13,
  }
  info.scans[1] = {
    :num => 2,
    :ms_level => 2,
    :time => 1.49,
    :precursor => MS::Precursor.new(:mz => 390.9291992, :intensity => 8.14409e+006)
  }
  info.scans[-1] = {
    :num => 20,
    :ms_level => 2,
    :time => 27.31,
    :precursor => MS::Precursor.new(:mz => 361.671875, :intensity => 572148.0)
  }
  info.scan_count0 = info.scan_count
  info.scan_count1 = 5
  info.scan_count2 = 15
  info.start_and_end_mz1 = [300.0, 1499]  # apparently nothing brushes right up to 1500
  # that first number on start_and_end_mz2 is a arbitrary as to accuracy...
  # I'm not sure the correct answer
  info.start_and_end_mz2 = [110.0, 1955]  ## again, this is based on data
end

describe MS::MSRun, "on mzXML version 2.0 files (w/o spectra)" do
  before(:all) do
    @info = MzXML_version_20_info
    start = Time.now
    @run = @info.klass.new(@info.file, :lazy => :no_spectra)
    puts "- read #{File.basename(@info.file)} in #{Time.now - start} seconds" if $specdoc
  end

  #it_should_behave_like "an msrun with basic, non-spectral information"
  it_should_behave_like 'a basic scan info generator'

  it 'fixes bad scan tags on the fly!' do
    # if this test works, this is true
  end
end

shared_examples_for "an mzXML version 2.0 file (w/spectra)" do
  before(:all) do
    @info = MzXML_version_20_info
    # first fix the file of bad scan tags
    @info.file
    #start = Time.now
    @fh = File.open(@info.file)
    @run = @info.klass.new(@fh, :lazy => @lazy_type)
    #puts "- read #{File.basename(@new_file)} in #{Time.now - start} seconds" if $specdoc
  end

  after(:all) do
    # @fh.close  # not sure why, but the filehandle is already closed!
    # Maybe because the filehandle went out of scope??
  end

  it_should_behave_like "an msrun with spectrum"  # <- trouble
  it_should_behave_like 'a basic scan info generator'
end

#[:io, :string, :not].each do |lazy_type|
[:io, :string, :not].each do |lazy_type|
  describe MS::MSRun, "mzXML v2.0 with :lazy => :#{lazy_type}" do 
    before(:all) { @lazy_type = lazy_type}
    it_should_behave_like "an mzXML version 2.0 file (w/spectra)"
  end

 end
  
Mzdata_105_info = MyOpenStruct.new do |info|
  info.file = Tfiles + '/opd1_2runs_2mods/data/020.mzData.xml'
  info.klass = MS::MSRun
  info.filetype = :mzdata
  info.version = '1.05'
  # NOTE that the real file drops the last scan!!  giving a mismatch
  info.scan_count = 20  
  info.start_time = 0.13002   # minutes == 0.00216667
  # This is the correct one!, but Thermo drops last scan
  # info.end_time = 5099.688    #84.9948
  #info.end_time = 84.968500*60  #   5098.11
  info.end_time = 0.455167 * 60 

  info.num_to_prec_mz_hash = {
    0 => nil,
    1 => nil,
    2 => 390.9291992,
    3 => 1121.944824,
    4 => 1321.913574,
    17 => nil,
    18 => 308.795959,
    19 => 444.983337,
    20 =>  361.671875,
    # 3620 => 357.0411987, Bioworks 3.3 is broken
  }

  info.scans = {}
  info.scans[0] = {
    :num => 1,
    :ms_level => 1,
    :time => 0.13002,  # a little rounding error coming from minutes
  }
  info.scans[1] = {
    :num => 2,
    :ms_level => 2,
    :time => 0.024833 * 60,   # 1.48998
    :precursor => MS::Precursor.new( :mz => 390.9291992, :intensity => 8.144094e+006),
  }
  info.scans[-1] = {
    :num => 20,
    :ms_level => 2,
    #:time => 5099.69, 
    #:time => 84.968500 * 60,  #   5098.11
    :time => 0.455167 * 60,

    :precursor => MS::Precursor.new( :mz => 361.671875, :intensity => 572148.0 ) # wrong
  }
  info.scan_count0 = info.scan_count
  info.scan_count1 = 5
  info.scan_count2 = 15 # should be 2715, they dropped the last scan!
  info.start_and_end_mz1 = [300.0, 1500.0]
  # This is the Correct one!!!, but Thermo drops last scan
  #info.start_and_end_mz2 = [112.0, 2000.0] 
  info.start_and_end_mz2 = [95.0, 1955]
end

describe MS::MSRun, "on mzData version 1.05 files (Bioworks3.3) (w/o spectra)" do
  before(:all) do
    @info = Mzdata_105_info
    start = Time.now
    @run = @info.klass.new(@info.file, :lazy => :no_spectra)
    puts "- read #{File.basename(@info.file)} in #{Time.now - start} seconds" if $specdoc
    puts "- [NOTE] mzData files from Thermo are missing their last scan!" if $specdoc
  end

  it_should_behave_like "an msrun with basic, non-spectral information"
  it_should_behave_like 'a basic scan info generator'

end

shared_examples_for "mzData v1.05 (Bioworks3.3) (w/spectra)" do
  before(:all) do
    @info = Mzdata_105_info  
    #start = Time.now
    @fh = File.open(@info.file)
    @run = @info.klass.new(@fh, :lazy => @lazy_type)
    #puts "- read #{File.basename(@info.file)} in #{Time.now - start} seconds" if $specdoc
    puts "- [NOTE] mzData files from Thermo are missing their last scan!" if $specdoc
  end

  it_should_behave_like "an msrun with spectrum"
  it_should_behave_like 'a basic scan info generator'

  it 'has (or can get) correct precursor intensities for all scans' do
    check_file = Tfiles + '/opd1_2runs_2mods/data/020.readw.mzXML'
    prec_inten_mzs = IO.readlines(check_file).grep(/precursorMz/).map do |line|
      if line =~ /Intensity="([\d\.e\+\-]+)">([\d\.e\+\-]+)</
        [$1.to_f, $2.to_f]
      else
        abort "didn't match for some crazy reason! (probably newline issues)"
      end
    end

    prec_mz_cnt = 0
    @run.scans.each_with_index do |scan,i|
      next if i % 4 == 0
      (exp_int, exp_mz) = prec_inten_mzs[prec_mz_cnt] 

      precursor = scan.precursor
      precursor.mz.should be_close(exp_mz, 0.00001)
      prec_inten = 
        if precursor.intensity.nil?
          precursor.parent.spectrum.intensity_at_mz(precursor.mz)
        else
          precursor.intensity
        end
      prec_inten.should be_close(exp_int, 51)

      prec_mz_cnt += 1
    end
  end
end

#[:string, :not, :io].each do |lazy_type|
[:io].each do |lazy_type|
 describe MS::MSRun, "mzData v1.05 with :lazy => :#{lazy_type}" do 
    before(:all) { @lazy_type = lazy_type}
    it_should_behave_like "mzData v1.05 (Bioworks3.3) (w/spectra)"
  end
end

describe 'reading a small file of twenty scans' do
  before(:all) do
    @file = Tfiles + "/opd1/twenty_scans.mzXML"
  end

  it 'retrieves times and spectra with all lazy types' do
    [:not, :string, :io].each do |lazy_type|

      File.open(@file) do |io|
        msrun = MS::MSRun.new(io, :lazy => lazy_type)


        (times, spectra) = msrun.times_and_spectra(1)
        etimes = %w(0.440000 5.150000 10.690000 16.400000 22.370000).map {|t| t.to_f }
        num_peaks = [992, 814, 796, 849, 813]
        tol = 0.000000001
        spectra[0].mzs[1].should be_close(301.430114746094, tol)
        spectra[0].intensities[1].should be_close(22192.0, tol)
        spectra[0].mzs[-1].should be_close(1499.09912109375, tol)
        spectra[0].intensities[-1].should be_close(111286.0, tol)

        spectra[-1].mzs[1].should be_close(301.243774414062, tol)
        spectra[-1].intensities[1].should be_close(77503.0, tol)
        spectra[-1].mzs[-1].should be_close(1499.42016601562, tol)
        spectra[-1].intensities[-1].should be_close(13.0, tol)

        num_peaks.each_with_index do |n,i|
          spectra[i].mzs.size.should == n
        end
        etimes.each_with_index do |t,i|
          times[i].should be_close(t, 0.00001)
        end
      end
    end
  end
end

describe MS::MSRun, 'with a small set of scans' do 
  it 'can add parent scans' do
    vals = [
      [1,1,0.13], 
      [2,2,0.23], 
      [3,2,0.33], 
      [4,3,0.43], 
      [5,3,0.53], 
      [6,1,0.63], 
      [7,2,0.73], 
      [8,3,0.83], 
      [9,2,0.93]
    ]
    precs = (0..(vals.size)).to_a.map do |x|
      MS::Precursor.new([x,100])
    end

    scans = vals.zip(precs).map do |ar,prec|
      scan = MS::Scan.new(ar)
      scan.precursor = prec
      scan
    end
    scans.size.should == vals.size
    s = scans
    parents = [nil,s[0],s[0],s[2],s[2],nil,s[5],s[6],s[5]]
    MS::MSRun.add_parent_scan(scans)
    scans.each_with_index do |scan,i|
      scan.precursor.parent.should == parents[i]
    end
  end
end

=begin
###################################################
# SHOULD IMPLEMENT BASIC INFO FOR ALL FILE TYPES
###################################################

require 'test/unit'
require 'ms/mzxml/parser'

class MSMzXML < Test::Unit::TestCase
  def initialize(arg)
    super(arg)
    @tfiles = File.dirname(__FILE__) + '/tfiles/'
    @tscans = @tfiles + "opd1/twenty_scans.mzXML"
    @big_file = "../bioworks2prophet/xml/opd00001_test_set/opd00001_prophprepped/000.mzXML"
  end

  def test_basic_info
    hash = MS::MzXML::Parser.new.basic_info(@tscans)
    assert_equal({:scan_count=>[20, 5, 15], :start_time=>0.44, :end_time=>27.05, :start_mz=>300.0, :end_mz=>1500.0, :ms_level=>1}, hash, "basic info the same")
  end

end

=end


