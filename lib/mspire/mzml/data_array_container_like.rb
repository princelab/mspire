require 'mspire/paramable'
require 'mspire/mzml/data_array'

module Mspire
  class Mzml
    module DataArrayContainerLike
      include Mspire::Paramable

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

      # returns a hash with id, index, defaultArrayLength
      def data_array_xml_atts
        {index: @index, id: @id, defaultArrayLength: default_array_length}
      end

    end
  end
end
