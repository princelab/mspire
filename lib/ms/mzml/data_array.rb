require 'base64'
require 'zlib'

module MS
  class Mzml
    class DataArray < Array

      DEFAULT_DTYPE = :float64
      DEFAULT_COMPRESSION = true
      DTYPE_TO_ACC = {
        float64: 'MS:1000523',
        float32: 'MS:1000521',
        # float16: 'MS:1000520',  # <- not supported w/o other gems
        int64: 'MS:1000522', # signed
        int32: 'MS:1000519', # signed
      }

      # the type of data array (:mz or :intensity)
      attr_accessor :type

      # requires a type, :mz or :intensity
      def initialize(_type, ar=[])
        @type = _type
        super(ar)
      end

      def self.to_mzml_string(array_ish, dtype=DEFAULT_DTYPE, compression=DEFAULT_COMPRESSION)
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

      def to_xml(builder, dtype=DEFAULT_DTYPE, compression=DEFAULT_COMPRESSION)
        base64 = self.class.to_mzml_string(self, dtype, compression)
        builder.binaryDataArray(encodedLength: base64.bytesize) do |bda_n|
          MS::CV::Param[ DTYPE_TO_ACC[dtype] ].to_xml(bda_n)
          MS::CV::Param[ compression ? 'MS:1000574' : 'MS:1000576' ].to_xml(bda_n)
          MS::CV::Param[ (@type == :mz) ? 'MS:1000514' : 'MS:1000515' ].to_xml(bda_n) # must be m/z or intensity 
          bda_n.binary(base64)
        end
      end

      # takes an array of DataArray objects or other kinds of objects
      def self.list_xml(arrays, builder)
        builder.binaryDataArrayList(count: arrays.size) do |bdal_n|
          arrays.zip([:mz, :intensity]) do |data_ar, typ|
            ar = data_ar.is_a?(MS::Mzml::DataArray) ? data_ar : MS::Mzml::DataArray.new(typ, data_ar)
            ar.type = typ unless ar.type
            ar.to_xml(bdal_n)
          end
        end
      end

    end
  end
end
