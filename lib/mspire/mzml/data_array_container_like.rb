require 'mspire/cv/paramable'
require 'mspire/mzml/data_array'

module Mspire
  class Mzml
    module DataArrayContainerLike
      include Mspire::CV::Paramable

      ###########################################
      # ATTRIBUTES
      ###########################################

      # (required) the spectrum id matching this general pattern: \S+=\S+( \S+=\S+)*)
      attr_accessor :id

      # (required [at xml write time]) the index in the spectrum list
      attr_accessor :index

      # (optional) an Mspire::Mzml::DataProcessing object
      attr_accessor :data_processing

      ###########################################
      # SUBELEMENTS
      ###########################################

      # (optional) an array of Mspire::Mzml::DataArray
      attr_accessor :data_arrays

      def default_array_length
        if @data_arrays
          if @data_arrays.first
            @data_arrays.first.size
          else
            0
          end
        else
          0
        end
      end

      # see SpectrumList for generating the entire list
      # the opt key :sub_elements can be used to pass in subelements whose
      # to_xml methods will be called.
      def to_xml(builder, opts={}, &block)
        atts = {id: @id, index: @index, defaultArrayLength: default_array_length}
        atts[:dataProcessingRef] = @data_processing.id if @data_processing
        atts.merge!(opts)
        raise "#{self.class} object must have index at xml writing time!" unless atts[:index] 

        builder.spectrum(atts) do |sp_n|
          super(sp_n) # params
          block.call(sp_n) if block
          Mspire::Mzml::DataArray.list_xml(@data_arrays, sp_n) if @data_arrays
        end
        builder
      end

    end
  end
end
