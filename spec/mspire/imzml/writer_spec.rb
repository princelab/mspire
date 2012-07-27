require 'spec_helper'

require 'mspire/imzml/writer'
require 'mspire/imzml/writer/commandline'
require 'mspire/spectrum'

describe Mspire::Imzml::Writer do

  before(:each) do
    @spectra = [
      Mspire::Spectrum.new([[1,2,3],[4,5,6]]),
      Mspire::Spectrum.new([[1,2,3],[4,5,6]]),
      Mspire::Spectrum.new([[1,2,3],[4,5,6]]),
    ]
    @config = {
      uuid: "d097f8103a8e012f2b130024e8b4cdae",
      mz_data_type: :float,
      mz_precision: 32,
      # just for fun, use floats for m/z and ints for intensities
      intensity_data_type: :int,
      intensity_precision: 32,
    }
  end

  it 'has an iterator that creates the proper x and y positions' do
    #config = { :scan_pattern => 'meandering', :scan_type => 'horizontal', :linescan_direction => 'left-right', :linescan_sequence => 'top-down', :max_dimensions_pixels => '3x2', :pixel_size => '2x2', :max_dimensions_microns => '6x4', :shots_per_position => 2 }
    writer = Mspire::Imzml::Writer.new
    testing = {

      %w(flyback horizontal left-right top-bottom) => [[1, 1], [1, 1], [2, 1], [2, 1], [3, 1], [3, 1], [1, 2], [1, 2], [2, 2], [2, 2], [3, 2], [3, 2]],
      %w(flyback horizontal left-right bottom-top) => [[1, 1], [1, 1], [2, 1], [2, 1], [3, 1], [3, 1], [1, 2], [1, 2], [2, 2], [2, 2], [3, 2], [3, 2]],
      %w(flyback horizontal right-left bottom-top) => [[1, 1], [1, 1], [2, 1], [2, 1], [3, 1], [3, 1], [1, 2], [1, 2], [2, 2], [2, 2], [3, 2], [3, 2]],
      %w(flyback horizontal right-left top-bottom) => [[1, 1], [1, 1], [2, 1], [2, 1], [3, 1], [3, 1], [1, 2], [1, 2], [2, 2], [2, 2], [3, 2], [3, 2]],
      %w(meandering horizontal left-right top-bottom) => [[1, 1], [1, 1], [2, 1], [2, 1], [3, 1], [3, 1], [3, 2], [3, 2], [2, 2], [2, 2], [1, 2], [1, 2]],
      %w(meandering horizontal left-right bottom-top) => [[1, 1], [1, 1], [2, 1], [2, 1], [3, 1], [3, 1], [3, 2], [3, 2], [2, 2], [2, 2], [1, 2], [1, 2]],
      %w(meandering horizontal right-left bottom-top) => [[1, 1], [1, 1], [2, 1], [2, 1], [3, 1], [3, 1], [3, 2], [3, 2], [2, 2], [2, 2], [1, 2], [1, 2]],
      %w(meandering horizontal right-left top-bottom) => [[1, 1], [1, 1], [2, 1], [2, 1], [3, 1], [3, 1], [3, 2], [3, 2], [2, 2], [2, 2], [1, 2], [1, 2]],
      %w(flyback vertical top-bottom left-right) => [[1, 1], [1, 1], [1, 2], [1, 2], [2, 1], [2, 1], [2, 2], [2, 2], [3, 1], [3, 1], [3, 2], [3, 2]],
      %w(flyback vertical bottom-top right-left) => [[3, 2], [3, 2], [3, 1], [3, 1], [2, 2], [2, 2], [2, 1], [2, 1], [1, 2], [1, 2], [1, 1], [1, 1]],
      %w(flyback vertical bottom-top left-right) => [[1, 2], [1, 2], [1, 1], [1, 1], [2, 2], [2, 2], [2, 1], [2, 1], [3, 2], [3, 2], [3, 1], [3, 1]],
      %w(flyback vertical top-bottom right-left) => [[3, 1], [3, 1], [3, 2], [3, 2], [2, 1], [2, 1], [2, 2], [2, 2], [1, 1], [1, 1], [1, 2], [1, 2]],
      %w(meandering vertical top-bottom left-right) => [[1, 1], [1, 1], [1, 2], [1, 2], [2, 2], [2, 2], [2, 1], [2, 1], [3, 1], [3, 1], [3, 2], [3, 2]],
      %w(meandering vertical bottom-top right-left) => [[3, 2], [3, 2], [3, 1], [3, 1], [2, 1], [2, 1], [2, 2], [2, 2], [1, 2], [1, 2], [1, 1], [1, 1]],
      %w(meandering vertical bottom-top left-right) => [[1, 2], [1, 2], [1, 1], [1, 1], [2, 1], [2, 1], [2, 2], [2, 2], [3, 2], [3, 2], [3, 1], [3, 1]],
      %w(meandering vertical top-bottom right-left) => [[3, 1], [3, 1], [3, 2], [3, 2], [2, 2], [2, 2], [2, 1], [2, 1], [1, 1], [1, 1], [1, 2], [1, 2]]
    }
    cats = %w(scan_pattern scan_type linescan_direction linescan_sequence).map(&:to_sym)
    testing. each do |(configs, expected)|
      config = Hash[ cats.zip(configs).map.to_a ]
    config[:max_dimensions_pixels] = '3x2'
    config[:shots_per_position] = 2
    writer.x_y_positions(config).should == expected
    end
  end

  it 'writes :processed binary file with spectra and returns DataArrayInfo objects' do
    write_to = TESTFILES + "/mspire/imzml/processed_binary.ibd"
    array = subject.write_binary(write_to, @spectra.each, @config.merge( {:data_structure => :processed} ))
    file_check(write_to)

    array.should be_an(Array)
    length = 3
    offsets = (16..76).step(12)
    encoded_length = 12

    array.each do |info_pair|
      info_pair.each do |obj| 
        obj.should be_a(Mspire::Imzml::DataArrayInfo)
        obj.length.should == length
        obj.encoded_length.should == encoded_length
        obj.offset.should == offsets.next
      end
    end
  end

  it 'writes :continuous binary file with spectra and returns DataArrayInfo objects' do
    write_to = TESTFILES + "/mspire/imzml/continuous_binary.ibd"
    array = subject.write_binary(write_to, @spectra.each, @config.merge( {:data_structure => :continuous} ))
    file_check(write_to)
    array.should be_an(Array)

    length = 3
    offsets = (28..52).step(12)
    encoded_length = 12
    first_offset = 16

    array.each do |info_pair|
      info_pair.each do |obj| 
        obj.should be_a(Mspire::Imzml::DataArrayInfo)
        obj.length.should == length
        obj.encoded_length.should == encoded_length
      end
      info_pair.first.offset.should == first_offset
      info_pair.last.offset.should == offsets.next
    end
  end

  describe 'full conversion of a file' do

    before do
      @file = TESTFILES + "/mspire/mzml/1_BB7_SIM_478.5.mzML"
    end

    # reads file and removes parts that change run to run
    def sanitize(string)
      string = sanitize_mspire_version_xml(string)
      reject = ['xmlns="http://psi.hupo.org/ms/mzml', 'universally unique identifier', 'ibd SHA-1']
      string.split(/\r?\n/).reject do |line| 
        reject.any? {|fragment| line.include?(fragment) }
      end.join("\n")
    end

    it 'converts sim files' do
      outbase = TESTFILES + "/mspire/imzml/1_BB7_SIM_478.5"
      Mspire::Imzml::Writer::Commandline.run([@file, @file, "--max-dimensions-microns", "72x2", "--max-dimensions-pixels", "72x2", "--outfile", outbase])
      # really just frozen for now until I inspect it more critically
      file_check( TESTFILES + "/mspire/imzml/1_BB7_SIM_478.5.imzML" ) do |st|
        sanitize(st)
      end
      file_check( TESTFILES + "/mspire/imzml/1_BB7_SIM_478.5.ibd" ) do |st|
        st.each_byte.map.to_a[20..-1]
      end
    end
  end


end
