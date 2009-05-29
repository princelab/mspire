
require File.expand_path( File.dirname(__FILE__) + '/../spec_helper' )
require 'ms/parser'

describe "a MS::Parser on a file", :shared => true do 
  it 'finds filetype and version on file and handle' do
    ft_version = nil
    File.open(@file) do |fh|
      ft_version = MS::Parser.filetype_and_version(fh)
    end
    ft_version.should == @filetype_version
    ft_version = MS::Parser.filetype_and_version(@file)
    ft_version.should == @filetype_version
  end

  it 'creates a sub-classed parser responding to "msrun"' do
    parser = MS::Parser.new(@file, :msrun) 
    parser.class.to_s.should match(/^MS::Parser::/)
    parser.class.to_s.should match(Regexp.new(Regexp.escape(@subclass)))
    parser.respond_to?(:msrun).should be_true
  end

  ########################################################################
  # NOTE: methods to verify parsing of information should be defined where
  # that information is required.
  # e.g. msrun_spec.rb will verify that msrun objects are created properly.
  # this is because we don't care how we get that file, just that we get it.
  # The whole process of parsing a file should be transparent to users.
  ########################################################################

end

describe MS::Parser, "on a RAW file (Xcalibur 1.3 SP 1)" do
  spec_large do
    before(:all) do
      @filetype = :raw
      @version = nil
      @filetype_version = [@filetype, @version]
      @file = Tfiles_large + '/opd1_2runs_2mods/data/020.RAW'
    end

    it 'finds filetype (NO version yet!) on file and handle' do
      ft_version = nil
      File.open(@file) do |fh|
        ft_version = MS::Parser.filetype_and_version(fh)
      end
      ft_version.should == @filetype_version
      ft_version = MS::Parser.filetype_and_version(@file)
      ft_version.should == @filetype_version
    end
  end
end

describe MS::Parser, "on an mzXML version 1 file" do
  spec_large do
    before(:all) do
      @filetype = :mzxml
      @version = '1.0'
      @filetype_version = [@filetype, @version]
      @subclass = 'MS::Parser::MzXML'
      @file = Tfiles_large + '/yeast_gly_mzXML/000.mzXML' 
    end
    it_should_behave_like "a MS::Parser on a file"
  end
end

describe MS::Parser, "on an mzXML version 2 file" do
  spec_large do
    before(:all) do
      @filetype = :mzxml
      @version = '2.0'
      @filetype_version = [@filetype, @version]
      @subclass = 'MS::Parser::MzXML'
      @file = Tfiles + '/opd1_2runs_2mods/data/020.readw.mzXML'
    end
    it_should_behave_like "a MS::Parser on a file"
  end
end

describe MS::Parser, "on an mzData version 1.05 file" do
  spec_large do
    before(:all) do
      @filetype = :mzdata
      @version = '1.05'
      @filetype_version = [@filetype, @version]
      @subclass = 'MS::Parser::MzData'
      @file = Tfiles + '/opd1_2runs_2mods/data/020.mzData.xml'
    end
    it_should_behave_like "a MS::Parser on a file"
  end
end

