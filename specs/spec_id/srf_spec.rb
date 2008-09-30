
require File.expand_path( File.dirname(__FILE__) + '/../spec_helper' )
require File.expand_path( File.dirname(__FILE__) + '/srf_spec_helper' )
require 'spec_id/srf'

require 'fileutils'

include SRFHelper

#tfiles = File.dirname(__FILE__) + '/tfiles/'
#tfiles_l = File.dirname(__FILE__) + '/tfiles_large/'
#tf_srf = tfiles_l + "7MIX_STD_110802_1.srf"
#tf_srf_inv = tfiles_l + "7MIX_STD_110802_1_INV.srf"
#if File.exist? tfiles_l
#  start = Time.now
#  $group = SRFGroup.new([tf_srf, tf_srf_inv]) 
#  $srf = $group.srfs.first
#  puts "Time to read and compile two SRF: #{Time.now - start} secs"
#end

class Hash
  def object_match(obj)
    self.all? do |k,v|
      k = k.to_sym
      retval = 
        if k == :peaks or k == :hits or k == :prots
          obj.send(k).size == v
        elsif v.class == Float
          delta = 
            if k == :ppm ; 0.0001          
            else ; 0.0000001          
            end
          (v - obj.send(k)).abs <= delta
        else
          obj.send(k) == v
        end
      if retval == false
        puts "BAD KEY: #{k}"
        puts "need: #{v}"
        puts "got: #{obj.send(k)}"
      end
      retval
    end
  end
end

klass = SRF

describe 'an srf reader', :shared => true do 
  before(:all) do
    @srf_obj = klass.new(@file)
  end

  it 'retrieves correct header info' do
    @header.object_match(@srf_obj.header).should be_true
    @dta_gen.object_match(@srf_obj.header.dta_gen).should be_true
  end

  # a few more dta params could be added in here:
  it 'retrieves correct dta files' do
    @dta_files_first.object_match(@srf_obj.dta_files.first).should be_true
    @dta_files_last.object_match(@srf_obj.dta_files.last).should be_true
  end

  # given an array of out_file objects, returns the first set of hits
  def get_first_peps(out_files)
    out_files.each do |outf|
      if outf.num_hits > 0
        return outf.hits
      end
    end
    return nil
  end

  it 'retrieves correct out files' do
    @out_files_first.object_match(@srf_obj.out_files.first).should be_true
    @out_files_last.object_match(@srf_obj.out_files.last).should be_true
    # first available peptide hit
    @out_files_first_pep.object_match(get_first_peps(@srf_obj.out_files).first).should be_true
    # last available peptide hit
    @out_files_last_pep.object_match(get_first_peps(@srf_obj.out_files.reverse).last).should be_true
  end

  xit 'retrieves correct params' do
   @params.object_match(@srf_obj.params).should be_true
  end

  it_should 'retrieve probabilities if available'
end


Expected_hash_keys = %w(header dta_gen dta_files_first dta_files_last out_files_first out_files_last out_files_first_pep out_files_last_pep params)

to_run = {
  '3.2' => {:hash => File_32, :file => '/opd1_2runs_2mods/sequest32/020.srf'},
  '3.3' => {:hash => File_33, :file => '/opd1_2runs_2mods/sequest33/020.srf'},
  '3.3.1' => {:hash => File_331, :file => '/opd1_2runs_2mods/sequest331/020.srf'},
}

to_run.each do |version,info|
  describe klass, " reading a version #{version} .srf file" do
    spec_large do
      before(:all) do
        @file = Tfiles_l + info[:file]
        Expected_hash_keys.each do |c|
          instance_variable_set("@#{c}", info[:hash][c.to_sym])
        end
      end
      it_should_behave_like "an srf reader"
    end
  end
end


describe klass, " reading a corrupted file" do
  it 'should read a null file from an aborted run w/o failing (but gives error msg)' do
    file = Tfiles + '/corrupted_900.srf'
    error_msg = Tfiles + '/error_msg.tmp'
    File.open(error_msg, 'w') do |err_fh|
      $stderr = err_fh
      srf_obj = klass.new(file) 
      srf_obj.base_name.should == '900'
      srf_obj.params.should be_nil
      header = srf_obj.header
      header.db_filename.should == "C:\\Xcalibur\\database\\sf_hs_44_36f_longesttrpt.fasta.hdr"
      header.enzyme.should == 'Enzyme:Trypsin(KR) (2)'
      dta_gen = header.dta_gen
      dta_gen.start_time.should be_close(1.39999997615814, 0.00000000001)
      srf_obj.dta_files.should == []
      srf_obj.out_files.should == []
    end
    IO.read(error_msg).should =~ /corrupted_900\.srf/
    File.unlink error_msg
  end
end

describe SRFGroup, 'creating an srg file' do
  it 'creates one given some non-existing, relative filenames' do 
    ## TEST SRG GROUPING:
    filenames = %w(my/lucky/filename /another/filename)
    @srg = SRFGroup.new
    @srg.filenames = filenames
    srg_file = Tfiles + '/tmp_srg_file.srg'
    @srg.to_srg(srg_file)
    File.exist?(srg_file).should be_true
    File.unlink(srg_file)
  end
end


# @TODO: this test needs to be created for a small mock dataset!!
describe SRF, 'creating dta files' do
  spec_large do 
    before(:all) do
      file = Tfiles_l + '/opd1_2runs_2mods/sequest33/020.srf'
      @srf = SRF.new(file)
    end

    it 'creates dta files' do
      @srf.to_dta_files
      File.exist?('020').should be_true
      File.directory?('020').should be_true
      File.exist?('020/020.3366.3366.2.dta').should be_true
      lines = IO.readlines('020/020.3366.3366.2.dta', "\r\n")
      lines.first.should == "1113.106493 2\r\n"
      lines[1].should == "164.5659 4817\r\n"
      
      FileUtils.rm_rf '020'
    end
  end

end
