require 'spec_helper'

require 'mspire/imzml/writer'
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
    expected_file = TESTFILES + "/mspire/imzml/processed_binary_check.ibd"
    write_to = TESTFILES + "/mspire/imzml/processed_binary.tmp.ibd"
    array = subject.write_binary(write_to, @spectra.each, @config.merge( {:data_structure => :processed} ))
    IO.read(write_to).should == IO.read(expected_file)
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
    File.unlink(write_to) if File.exist?(write_to)
  end

  it 'writes :continuous binary file with spectra and returns DataArrayInfo objects' do
    expected_file = TESTFILES + "/mspire/imzml/continuous_binary_check.ibd"
    write_to = TESTFILES + "/mspire/imzml/continuous_binary.tmp.ibd"
    array = subject.write_binary(write_to, @spectra.each, @config.merge( {:data_structure => :continuous} ))
    IO.read(write_to).should == IO.read(expected_file)
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
    File.unlink(write_to) if File.exist?(write_to)
  end


end
