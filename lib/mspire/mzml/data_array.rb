require 'base64'
require 'zlib'
require 'mspire/cv/paramable'

module Mspire
  class Mzml
    class DataArray < Array
      alias_method :array_initialize, :initialize
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

      # the type of data array (:mz, :intensity, :mz_external, or :intensity_external)
      attr_accessor :type

      def initialize(*args)
        array_initialize(*args)
      end

      # returns a new Mspire::Mzml::DataArray object (an array)
      #
      #     args:
      #       base64, set-like               # where set-like responds to include?
      #       base64, type=:float64, compression=true
      #
      #     examples:
      #     Mspire::Mzml::Spectrum.unpack_binary('eJxjYACBD/YMEOAAoTgcABe3Abg=', ['MS:1000574', MS:1000523']).
      #     Mspire::Mzml::Spectrum.unpack_binary("ADBA/=", :float32, true)
      #     Mspire::Mzml::Spectrum.unpack_binary("ADBA/=") # uses float64 and compression
      def self.from_binary(base64, *args)
        if args.first.respond_to?(:include?)
          accessions = args.first
          compressed =
            if accessions.include?('MS:1000574') then true # zlib compression
            elsif accessions.include?('MS:1000576') then false # no compression
            else raise 'no compression info: check your MS accession numbers'
            end
          precision_unpack = 
            if accessions.include?('MS:1000523') then 'E*'
            elsif accessions.include?('MS:1000521') then 'e*'
            else raise 'unrecognized precision: check your MS accession numbers'
            end
        else
          compressed = args.last || true
          precision_unpack =
            case args.first
            when :float64
              'E*'
            when :float32
              'e*'
            when nil
              'E*'
            else
              raise ArgumentError, "#{args.first} must be one of :float64, :float32 or other acceptable type"
            end
        end
        data = base64.unpack("m*").first
        unzipped = compressed ? Zlib::Inflate.inflate(data) : data
        self.new( unzipped.unpack(precision_unpack) )
      end

      # returns a base64 string that can be used for xml representations of
      # the data
      #
      #     args:
      #       array-like  set-like               # where set-like responds to include?
      #       array-like  type=:float64, compression=true
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
          @params.each {|param| param.to_xml(bda_n) } if @params
          unless @external
            Mspire::CV::Param[ DTYPE_TO_ACC[dtype] ].to_xml(bda_n)
            Mspire::CV::Param[ compression ? 'MS:1000574' : 'MS:1000576' ].to_xml(bda_n)
            if @type
              accession = ( (@type == :mz) ? 'MS:1000514' : 'MS:1000515' )
              Mspire::CV::Param[accession].to_xml(bda_n)
              bda_n.binary(base64)
            end
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
                real_data_array = Mspire::Mzml::DataArray.new(data_ar)
                real_data_array.type = typ
                real_data_array
              end
            ar.type = typ unless ar.type
            ar.to_xml(bdal_n)
          end
        end
      end

    end
  end
end
