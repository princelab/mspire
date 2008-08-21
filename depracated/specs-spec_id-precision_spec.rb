require File.dirname(__FILE__) + '/../spec_helper'

describe SpecID, "finding precision for pephits" do

  before(:all) do
    @tf_bioworks_esmall_xml = Tfiles + "/bioworks_with_INV_small.xml" 
    @tf_bioworks_shuff = Tfiles + "/bioworks_with_SHUFF_small.xml"
    @tf_html = Tfiles + "ppv.html"
    @tf_png = Tfiles + "ppv.png"
    @nodelete = false
  end

  it 'finds precision in concatenated files' do
    output = `#{@cmd} -o #{@tf_html} -f SHUFF_ --prefix #{@tf_bioworks_shuff}`
    puts output

    IO.read(@tf_html).should =~ /<table.*<\/table>/m  # has table
    IO.read(@tf_html).should =~ /10.*0.3000/m   # has values
    [@tf_html, @tf_png].each do |file|
      file.should exist
      File.unlink(file) unless @nodelete
    end
  end    

  xit 'finds precision on multiple files' do
    output = `#{@cmd} -o #{@tf_html} -f SHUFF_,INV_ --prefix #{@tf_bioworks_shuff} #{@tf_bioworks_esmall_xml}`
    IO.read(@tf_html).should =~ /<table.*<\/table>/m  # has table
    IO.read(@tf_html).should =~ /1.*1.0000.*1.*1.0000.*0.*0.*15.*0.8667/m # has values
    [@tf_html, @tf_png].each do |file|
      file.should exist
      File.unlink(file) unless @nodelete
    end
  end

  xit 'can calculate area under the curve' do
    file = Tfiles + 'ppv_area.txt'
    `#{@cmd} -o #{file} -a -f SHUFF_ --prefix #{@tf_bioworks_shuff}`
    file.should exist
    output = IO.read(file)
    outupt.should =~ /Prec.*7.39206/  # frozen
    File.unlink file
     
    outfile = File.join(File.dirname(__FILE__), 'other.html')
    `#{@cmd} -o #{outfile} -f SHUFF_ --prefix #{@tf_bioworks_shuff}`
    File.unlink outfile
    File.unlink File.join(File.dirname(__FILE__),'other.png')
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

