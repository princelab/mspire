require 'core_ext/enumerable'
require 'delegate'

module Mspire
  class Mzml
    class IOIndexableList < SimpleDelegator

      # arg may be an array of objects or an IOIndex object
      def initialize(default_data_processing, arg)
        @default_data_processing = default_data_processing
        __setobj__(arg)
      end

      def to_xml(builder)
        xml_name = self.class.split('::').last
        xml_name[0] = xml_name[0].downcase
        builder.tag!(xml_name.to_sym, count: self.size, defaultDataProcessingRef: @default_data_processing.id) do |iol_n|
          self.each_with_index do |obj,i|
            obj.index = i unless obj.index
            obj.to_xml(iol_n)
          end
        end
        builder
      end

    end
  end
end
