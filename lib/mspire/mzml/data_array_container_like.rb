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

      # returns a hash with id, index, defaultArrayLength and the proper
      # dataProcessing attributes filled out.
      def data_array_xml_atts(default_ids)
        atts = {id: @id, index: @index, defaultArrayLength: default_array_length}
        if @data_processing && default_ids[:data_processing] != @data_processing.id 
          atts[:dataProcessingRef] = @data_processing.id 
        end
        atts
      end

    end
  end
end
