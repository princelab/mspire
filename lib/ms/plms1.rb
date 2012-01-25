
require 'write_file_or_string'
require 'ms/spectrum'
require 'stringio'
require 'openany'

module MS

=begin
  # if given scans, will use those, or optionally takes a block where an
  # array of ms1 scans are yielded and it expects Enumerable scans back.
  def to_plms1(scans=nil)
    times = []
    scan_numbers = []
    spectra = []

    unless scans
      scans = []
      self.each(:ms_level => 1, :precursor => false) do |scan|
        scans << scan
      end
    end

    if block_given?
      scans = yield(scans)
    end

    scans.each do |scan|
      times << scan.time
      scan_numbers << scan.num
      spec = scan.spectrum
      spectra << [spec.mzs.to_a, spec.intensities.to_a]
    end
    plms1 = Plms1.new
    plms1.times = times
    plms1.scan_numbers = scan_numbers
    plms1.spectra = spectra
    plms1
  end
=end

  # Prince Lab MS 1: a simple format for reading and writing 
  # MS1 level mass spec data
  # 
  # see MS::Plms1::SPECIFICATION for the file specification
  class Plms1
    SPECIFICATION =<<-HERE
        # The file format contains no newlines but is shown here broken into lines for
        # clarity.  Data should be little endian.  Comments begin with '#' but are not
        # part of the spec. Angled brackets '<>' indicate the data type and square
        # brackets '[]' the name of the data. An ellipsis '...' represents a
        # continuous array of data points.

        <uint32>[Number of scans]
        <uint32>[scan number] ...  # array of scan numbers as uint32
        <float64>[time point] ...  # array of time points as double precision floats (in seconds)
        # this is a repeating unit based on [Number of scans]:
        <uint32>[Number of data rows]  #  almost always == 2 (m/z, intensity)
        # this is a repeating unit based on [Number of data rows]
        <uint32>[Number of data points]
        <float64>[data point] ...  # array of data points as double precision floats
    HERE

    # an array of scan numbers
    attr_accessor :scan_numbers
    # an array of time data
    attr_accessor :times
    # an array that contains spectrum objects
    attr_accessor :spectra

    def initialize(_scan_numbers=[], _times=[], _spectra=[])
      (@scan_numbers, @times, @spectra) = [_scan_numbers, _times, _spectra]
    end

    # returns an array of Integers
    def read_uint32(io, cnt=1)
      io.read(cnt*4).unpack("V*")
    end

    # returns an array of Floats
    def read_float64(io, cnt=1)
      io.read(cnt*8).unpack("E*")
    end

    # returns self for chaining
    def read(io_or_filename)
      openany(io_or_filename) do |io|
        num_scans = read_uint32(io)[0]
        @scan_numbers = read_uint32(io, num_scans)
        @times = read_float64(io, num_scans)
        @spectra = num_scans.times.map do
          data = read_uint32(io)[0].times.map do
            read_float64(io, read_uint32(io)[0])
          end
          MS::Spectrum.new(data)
        end
      end
      self
    end

    def write_uint32(out, data)
      to_pack = data.is_a?(Array) ? data : [data]
      out << to_pack.pack('V*')
    end

    def write_float64(out, data)
      to_pack = data.is_a?(Array) ? data : [data]
      out << to_pack.pack('E*')
    end

    # writes an ascii version of the format
    # It is the same as the binary format, except a newline follows each
    # length indicator or array of data. An empty line represents an empty
    # array.
    def write_ascii(filename=nil)
      write_file_or_string(filename) do |out|
        out.puts scan_numbers.size
        out.puts scan_numbers.join(' ')
        out.puts times.join(' ')
        spectra.each do |spectrum|
          out.puts spectrum.size
          if spectrum.size > 0
            out.puts spectrum.mzs.size
            out.puts spectrum.mzs.join(' ')
            out.puts spectrum.intensities.size
            out.puts spectrum.intensities.join(' ')
          end
        end
      end
    end

    # returns the string if no filename given 
    def write(filename=nil, ascii=false)
      if ascii
        write_ascii(filename)
      else
        write_file_or_string(filename) do |out|
          write_uint32(out, spectra.size)
          write_uint32(out, scan_numbers)
          write_float64(out, times)
          spectra.each do |spectrum|
            write_uint32(out, spectrum.size)  # number of rows
            if spectrum.size > 0
              mzs = spectrum.mzs
              write_uint32(out, mzs.size)
              write_float64(out, mzs)
              intensities = spectrum.intensities
              write_uint32(out, intensities.size)
              write_float64(out, intensities)
            end
          end
        end
      end
    end
  end
end
