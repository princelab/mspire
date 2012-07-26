require 'base64'
require 'zlib'
require 'mspire/cv/paramable'

module Mspire
  class Mzml
  end
end


class Mspire::Mzml::DataArray < Array
  alias_method :array_init, :initialize
  include Mspire::CV::Paramable

  DEFAULT_DTYPE = :float64
  DEFAULT_COMPRESSION = true
  DTYPE_TO_ACC = {
    float64: 'MS:1000523',
    float32: 'MS:1000521',
    # float16: 'MS:1000520',  # <- not supported w/o other gems
    int64: 'MS:1000522', # signed
    int32: 'MS:1000519', # signed
  }
  TYPE_XML = {
    mz: '<cvParam cvRef="MS" accession="MS:1000514" name="m/z array"/>',
    intensity: '<cvParam cvRef="MS" accession="MS:1000515" name="intensity array"/>'
  }

  def initialize(*args)
    params_init # paramable
    array_init(*args)
  end

  # takes :mz or :intensity and sets the proper param among cvParams.  Does not do
  # referenceableParamGroup resolution.
  def type=(symbol)
    new_cv_params = []
    already_present = false
    cvs = ['MS:1000514', 'MS:1000515']
    cvs.reverse! if symbol == :intensity
    (keep, remove) = cvs

    @cv_params.each do |param|
      new_cv_params << param unless param.accession == remove
      (already_present = true) if (param.accession == keep)
    end
    new_cv_params.push(Mspire::CV::Param[keep]) unless already_present
    @cv_params = new_cv_params
    symbol
  end

  # :mz or :intensity (or nil if none found)
  def type
    each_accessionable_param do |param|
      return :mz if (param.accession == 'MS:1000514')
      return :intensity if (param.accession == 'MS:1000515')
    end
    nil
  end

  # (optional) the DataProcessing object associated with this DataArray
  attr_accessor :data_processing

  # set this if the data is written to an external file (such as the ibd
  # file for imzML files)
  attr_accessor :external

  def self.empty_data_arrays
    [self.new, self.new]
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
      super(bda_n)
      unless self.external
        # can significantly speed up the below 2 lines:
HELLO LOOOKEY !!!!!! HERER need to get attributes correct first...
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
          if data_ar.is_a?(Mspire::Mzml::DataArray) then data_ar
          else Mspire::Mzml::DataArray.new(data_ar) end
        ar.type = typ unless ar.type
        ar.to_xml(bdal_n)
      end
    end
  end
end
