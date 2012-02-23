require 'base64'
require 'zlib'
require 'ms/cv/paramable'

module MS
  class Mzml
    class DataArray < Array
      include MS::CV::Paramable

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

      # requires a type, :mz, :intensity, :mz_external, or :intensity_external
      # (external types used in imzml)
      def initialize(_type, opts={params: []})
        @type = _type
        @external = !!(@type.to_s =~ /external$/)
      end

      def self.to_binary(array_ish, dtype=DEFAULT_DTYPE, compression=DEFAULT_COMPRESSION)
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
        encoded_length = 
          if @external
            0
          else
            base64 = self.class.to_binary(self, dtype, compression) unless @external
            base64.bytesize
          end

        builder.binaryDataArray(encodedLength: encoded_length) do |bda_n|
          @params.each {|param| param.to_xml } if @params
          unless @external
            MS::CV::Param[ DTYPE_TO_ACC[dtype] ].to_xml(bda_n)
            MS::CV::Param[ compression ? 'MS:1000574' : 'MS:1000576' ].to_xml(bda_n)
            MS::CV::Param[ (@type == :mz) ? 'MS:1000514' : 'MS:1000515' ].to_xml(bda_n) # must be m/z or intensity 
            bda_n.binary(base64)
          end
        end
      end

      # takes an array of DataArray objects or other kinds of objects
      def self.list_xml(arrays, builder)
        puts "EHLLO"
        p arrays
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
