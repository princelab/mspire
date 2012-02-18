
require 'ms/cv/describable'

module MS
  class Mzml
    class Spectrum
      include MS::CV::Describable

      # specifies 64-bit float with compression as the default encoding
      DEFAULT_ENCODING = { 
        mz: { dtype: 'MS:1000523', compression: true }, 
        intensity: {dtype: 'MS:1000523', compression: true } 
      }

      ###########################################
      # ATTRIBUTES
      ###########################################
      
      # (required) the spectrum id matching this general pattern: \S+=\S+( \S+=\S+)*)
      attr_accessor :id

      # the index in the spectrum list
      attr_accessor :index

      # (optional) an MS::Mzml::DataProcessing object
      attr_accessor :data_processing

      # (optional) an MS::Mzml::SourceFile object
      attr_accessor :source_file

      # (optional) The identifier for the spot from which this spectrum was derived, if a
      # MALDI or similar run.
      attr_accessor :spot_id

      ###########################################
      # SUBELEMENTS
      ###########################################

      # (optional) List and descriptions of scans.
      attr_accessor :scans

      # (optional) List and descriptions of precursor isolations to the spectrum
      # currently being described, ordered.
      attr_accessor :precursors

      # (optional) List and descriptions of product isolations to the spectrum
      # currently being described, ordered.
      attr_accessor :products

      # (optional) an array of MS::Mzml::DataArray
      attr_accessor :data

      # the most common param to pass in would be ms level: 'MS:1000511'
      #
      # This would generate a spectrum of ms_level=2 :
      #
      #     MS::Mzml::Spectrum.new(0, "scan=1") do
      #       param 'MS:1000511', 2
      #     end
      def initialize(index, id, *params, &block)
        @index, @id = index, id
        super(*params, &block)
      end

      def default_array_length
        @data ? @data.first.size : 0
      end

      # see SpectrumList for generating the entire list
      def to_xml(builder, opts={})
        mz_encoding = DEFAULT_ENCODING[:mz].merge(opts[:mz])
        int_encoding = DEFAULT_ENCODING[:intensity].merge(opts[:intensity])
        atts = {id: @id, index: @index, defaultArrayLength: default_array_length}
        atts[:dataProcessingRef] = @data_processing.id if @data_processing
        atts[:sourceFile] = @source_file.id if @source_file
        atts[:spotID] = @spot_id if @spot_id
        builder.spectrum(atts) do |sp_n|
          super(sp_n)

          # the data itself
          data.each do |array|
            # TODO: support custom MS::Mzml::DataArray objects that would
            # specify specific encoding behavior. 

          end
        end
        builder
      end

    end
  end
end
