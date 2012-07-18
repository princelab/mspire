require 'base64'
require 'zlib'
require 'mspire/cv/paramable'

module Mspire
  class Mzml
  end
end


class Mspire::Mzml::DataArray < Array
  include Mspire::CV::Paramable
  alias_method :params_to_xml, :to_xml

  DEFAULT_DTYPE = :float64
  DEFAULT_COMPRESSION = true
  DTYPE_TO_ACC = {
    float64: 'MS:1000523',
    float32: 'MS:1000521',
    # float16: 'MS:1000520',  # <- not supported w/o other gems
    int64: 'MS:1000522', # signed
    int32: 'MS:1000519', # signed
  }

  # :mz or :intensity
  def type
    if params
      accs_params = accessionable_params
      if accs_params.any? {|param| param.accession == 'MS:1000514' }
        :mz
      elsif accs_params.any? {|param| param.accession == 'MS:1000515' }
        :intensity
      end
    end
  end

  # (optional) the DataProcessing object associated with this DataArray
  attr_accessor :data_processing

  # set this if the data is written to an external file (such as the ibd
  # file for imzML files)
  attr_accessor :external

  def self.data_arrays_from_xml(xml, ref_hash)
    data_arrays = xml.children.map do |binary_data_array_n|
      Mspire::Mzml::DataArray.from_xml(binary_data_array_n, ref_hash)
    end
    (data_arrays.size > 0) ? data_arrays : [Mspire::Mzml::DataArray.new, Mspire::Mzml::DataArray.new]
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

  # returns a base64 string that can be used for xml representations of
  # the data
  #
  #     args:
  #       array-like  set-like               # where set-like responds to include?
  #       array-like  dtype=:float64, compression=true
  def self.to_binary(array_ish, *args)
    if args.first.respond_to?(:include?)
      accessions = args.first
      dtype = 
        if accessions.include?('MS:1000521') 
          :float32
        else
          :float64
        end
      compression = accessions.include?('MS:1000576') ? false : true 
    else
      dtype = args[0] || DEFAULT_DTYPE
      compression = args[1] || DEFAULT_COMPRESSION
    end

    pack_code = 
      case dtype
      when :float64 ; 'E*'
      when :float32 ; 'e*'
      when :int64   ; 'q<*'
      when :int32   ; 'l<*'
      else ; raise "unsupported dtype: #{dtype}"
      end
    # TODO: support faster pack method for NArray's in future
    string = array_ish.to_a.pack(pack_code) 
    string = Zlib::Deflate.deflate(string) if compression
    Base64.strict_encode64(string)
  end

  # calls the class to_binary method with self and the given args
  def to_binary(*args)
    self.class.to_binary(self, *args)
  end

  def to_xml(builder, dtype=DEFAULT_DTYPE, compression=DEFAULT_COMPRESSION)
    encoded_length = 
      if @external
        0
      else
        base64 = self.class.to_binary(self, dtype, compression)
        base64.bytesize
      end

    builder.binaryDataArray(encodedLength: encoded_length) do |bda_n|
      params_to_xml(bda_n)
      unless self.external
        Mspire::CV::Param[ DTYPE_TO_ACC[dtype] ].to_xml(bda_n)
        Mspire::CV::Param[ compression ? 'MS:1000574' : 'MS:1000576' ].to_xml(bda_n)
        bda_n.binary(base64)
      end
    end
  end

  # takes an array of DataArray objects or other kinds of objects
  def self.list_xml(arrays, builder)
    builder.binaryDataArrayList(count: arrays.size) do |bdal_n|
      arrays.zip([:mz, :intensity]) do |data_ar, typ|
        ar = 
          if data_ar.is_a?(Mspire::Mzml::DataArray)
            data_ar
          else
            Mspire::Mzml::DataArray.new(data_ar)
          end
        ar.type = typ unless ar.type
        ar.to_xml(bdal_n)
      end
    end
  end
end
