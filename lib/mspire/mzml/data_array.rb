require 'base64'
require 'zlib'
require 'mspire/cv/paramable'

module Mspire
  class Mzml
  end
end


# Mspire::Mzml::DataArray's are currently implemented as a standard Ruby
# array.  Data may be input or output with less precision, but a standard data
# array will be accessible from ruby as Float (float64).  Thus, the params
# merely alter what will be output to xml, so, to alter what is written with
# to_xml, change the params.  If no params are changed in the data array it
# will be written with the same precision as it was read in with.
class Mspire::Mzml::DataArray < Array 
  alias_method :array_init, :initialize
  include Mspire::CV::Paramable

  DEFAULT_DTYPE_ACC = 'MS:1000523' # float64
  DEFAULT_COMPRESSION_ACC = 'MS:1000574'
  COMPRESSION_ACC = 'MS:1000574'
  NO_COMPRESSION_ACC = 'MS:1000576'
  ACC_TO_DTYPE = {
    'MS:1000523' => :float64,
    'MS:1000521' => :float32,
    #'MS:1000520' => :float16,  # <- not supported w/o other gems
    'MS:1000522' => :int64, # signed
    'MS:1000519' => :int32, # signed
  }
  ACC_TO_UNPACK_CODE = {
    'MS:1000523' => 'E*',
    'MS:1000521' => 'e*',
    #'MS:1000520' => :float16,  # <- not supported w/o other gems
    'MS:1000522' => 'q<*',
    'MS:1000519' => 'l<*',
  }

  DTYPE_ACCS = ACC_TO_DTYPE.keys

  # unless data type (see DTYPE_TO_ACC) or TYPE
  def initialize(*args)
    params_init # paramable
    array_init(*args)
  end

  # (optional) the DataProcessing object associated with this DataArray
  attr_accessor :data_processing

  # set this if the data is written to an external file (such as the ibd
  # file for imzML files)
  attr_accessor :external

  # returns a DataArray object. Analogous to [] for creating an array.
  def self.[](*data)
    self.new(data)
  end

  # returns an array of DataArray objects based on the given arrays
  def self.from_arrays(arrays)
    arrays.map {|ar| self.new(ar) }
  end

    # returns an array of DataArray objects (2)
  def self.empty_data_arrays(num=2)
    Array.new(num) { self.new }
  end

  def self.data_arrays_from_xml(xml, link)
    data_arrays = xml.children.map do |binary_data_array_n|
      Mspire::Mzml::DataArray.from_xml(binary_data_array_n, link)
    end
    (data_arrays.size > 0) ? data_arrays : empty_data_arrays
  end

  def self.from_xml(xml, link)
    da = self.new 
    binary_n = da.describe_from_xml!(xml, link[:ref_hash])

    if (dp_id = xml[:dataProcessingRef])
      da.data_processing = link[:data_processing_hash][dp_id]
    end

    zlib_compression = nil
    precision_unpack = nil
    # could also implement with set or hash lookup (need to test for
    # speed)
    da.each_accessionable_param do |param|
      acc = param.accession
      unless zlib_compression || zlib_compression == false
        case acc
        when 'MS:1000574' then zlib_compression = true
        when 'MS:1000576' then zlib_compression = false
        end
      end
      unless precision_unpack
        case acc
        when 'MS:1000523' then precision_unpack = 'E*'
        when 'MS:1000521' then precision_unpack = 'e*'
        end
      end
    end

    data = binary_n.text.unpack("m*").first

    # some implementations leave data blank if there aren't peaks
    # even if they say it is zlib compressed...
    unzipped = 
      if data.size > 0 then ( zlib_compression ? Zlib::Inflate.inflate(data) : data )
      else data end
    da.replace( unzipped.unpack(precision_unpack) )
    da
  end

  # creates a base64 binary string based on the objects params.  If no dtype
  # or compression are specified, then it will be set (i.e., params added to
  # the object).
  def to_binary
    # single pass over params for speed
    pack_code = nil
    compression = nil
    each_accessionable_param do |param|
      acc = param.accession
      if !pack_code && (code=ACC_TO_UNPACK_CODE[acc])
        pack_code = code
      end
      if compression.nil?
        compression = 
          case acc
          when COMPRESSION_ACC then true
          when NO_COMPRESSION_ACC then false
          end
      end
    end
    # can speed these up:
    unless pack_code
      describe! DEFAULT_DTYPE_ACC
      pack_code = ACC_TO_UNPACK_CODE[DEFAULT_DTYPE_ACC]
    end
    if compression.nil?
      describe! DEFAULT_COMPRESSION_ACC
      compression = 
        case DEFAULT_COMPRESSION_ACC
        when COMPRESSION_ACC then true
        when NO_COMPRESSION_ACC then false
        end
    end

    # TODO: support faster pack method with nmatrix or narray
    string = self.pack(pack_code) 
    string = Zlib::Deflate.deflate(string) if compression
    Base64.strict_encode64(string)
  end

  # will set the data type to DEFAULT_DTYPE and compression if n
  def to_xml(builder)
    encoded_length = 
      if @external
        0
      else
        base64 = to_binary
        base64.bytesize
      end

    builder.binaryDataArray(encodedLength: encoded_length) do |bda_n|
      super(bda_n)
      bda_n.binary(base64) unless self.external
    end
  end

  # takes an array of DataArray objects or other kinds of objects
  def self.list_xml(arrays, builder)
    builder.binaryDataArrayList(count: arrays.size) do |bdal_n|
      arrays.each do |ar|
        ar.to_xml(bdal_n)
      end
    end
  end
end
