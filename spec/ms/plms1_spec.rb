require 'spec_helper'

require 'ms/plms1'
require 'ms/spectrum'

describe 'plms1 - Prince Lab MS 1 specification' do
  before do
    @keyfile = TESTFILES + "/plms1/output.key" 
    times = [0.55, 0.9]
    scan_numbers = [1,2]
    spectra = [
      MS::Spectrum.new([[300.0, 301.5, 303.1], [10, 20, 35.5]]),
      MS::Spectrum.new([[300.5, 302, 303.6], [11, 21, 36.5]])
    ]
    @plms1_obj = MS::Plms1.new(scan_numbers, times, spectra)
    @outfile = @keyfile.sub(/\.key$/, ".tmp")
  end

  it 'has a detailed specification' do
    specification = MS::Plms1::SPECIFICATION
    specification.should be_an_instance_of String
    (specification.size > 50).should == true
  end

  it 'writes a plms1 file' do
    @plms1_obj.write(@outfile)
    File.exist?(@outfile).should == true
    IO.read(@outfile, :mode => 'rb').should == IO.read(@keyfile, :mode => 'rb')
    File.unlink(@outfile) if File.exist?(@outfile)
  end

  it 'reads a plms1 file' do
    obj = MS::Plms1.new.read(@keyfile)
    [:scan_numbers, :times, :spectra].each do |val|
      obj.send(val).should == @plms1_obj.send(val)
    end
  end
end
