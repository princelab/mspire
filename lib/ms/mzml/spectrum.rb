require 'ms/cv/describable'
require 'ms/mzml/data_array'

module MS
  class Mzml
    class Spectrum
      include MS::CV::Describable

      ###########################################
      # ATTRIBUTES
      ###########################################
      
      # (required) the spectrum id matching this general pattern: \S+=\S+( \S+=\S+)*)
      attr_accessor :id

      # (required [at xml write time]) the index in the spectrum list
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
      #     MS::Mzml::Spectrum.new(0, "scan=1", 'MS:1000511')
      def initialize(id, index=nil, *params, &block)
        @description = MS::CV::Description.new(*params)
        @index, @id = index, id
        block.call(self) if block
      end

      def default_array_length
        @data ? @data.first.size : 0
      end

      # see SpectrumList for generating the entire list
      def to_xml(builder, opts={})
        raise "#{self.class} objects must have defined index before to_xml is called" unless @index
        atts = {id: @id, index: @index, defaultArrayLength: default_array_length}
        atts[:dataProcessingRef] = @data_processing.id if @data_processing
        atts[:sourceFile] = @source_file.id if @source_file
        atts[:spotID] = @spot_id if @spot_id

        builder.spectrum(atts) do |sp_n|
          @description.to_xml(sp_n)
          MS::Mzml::DataArray.list_xml(data, sp_n)
        end
        builder
      end

    end
  end
end
