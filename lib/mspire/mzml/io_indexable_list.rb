require 'core_ext/enumerable'
require 'delegate'

module Mspire
  class Mzml
    class IOIndexableList < SimpleDelegator
      # arg may be an array of objects or 
      def initialize(default_data_processing, arg)
        @default_data_processing = default_data_processing
        __setobj__(arg)
      end

      def to_xml(builder)
        builder.tag!(self.class (count: self.size, defaultDataProcessingRef: @default_data_processing.id) do |spl_n|

          WORKING HERE!


          self.each_with_index do |spectrum,i|
            spectrum.index = i unless spectrum.index
            spectrum.to_xml(spl_n)
          end
        end
        builder
      end



    end
  end
end
