require File.expand_path( File.dirname(__FILE__) + '/../spec_helper' )


describe 'ms_to_lmat.rb' do

  before(:all) do
    @progname = 'ms_to_lmat.rb'
    @mzxml = Tfiles + "/opd1/twenty_scans.mzXML"
    @ans_lmata = Tfiles + "/opd1/twenty_scans_answ.lmata"
    @ans_lmat = Tfiles + "/opd1/twenty_scans_answ.lmat"
  end

  it_should_behave_like "a cmdline program"

  it 'creates the correct lmata (ascii) file' do
    cmd = "#{@cmd} #{@mzxml} --ascii"   
    `#{cmd}`
    newfile = @mzxml.sub(".mzXML", ".lmata")
    newfile.exist_as_a_file?.should be_true
    IO.read(newfile).should == IO.read(@ans_lmata)
    File.unlink(newfile)
  end


  it 'creates the correct lmat (binary) file' do
    cmd = "#{@cmd} #{@mzxml}"   
    `#{cmd}`
    newfile = @mzxml.sub(".mzXML", ".lmat")
    newfile.exist_as_a_file?.should be_true
    IO.read(newfile).should == IO.read(@ans_lmat)
    File.unlink(newfile)
  end
end

