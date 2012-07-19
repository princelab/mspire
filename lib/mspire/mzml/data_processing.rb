require 'mspire/mzml/list'
require 'mspire/mzml/processing_method'

module Mspire
  class Mzml
    class DataProcessing
      extend Mspire::Mzml::List

      attr_accessor :id, :processing_methods

      # yields self if given a block
      def initialize(id, processing_methods=[])
        @id, @processing_methods = id, processing_methods
        yield(self) if block_given?
      end

      def to_xml(builder)
        builder.dataProcessing( id: @id ) do |dp_n|
          processing_methods.each_with_index do |processing_method,order|
            processing_method.to_xml(dp_n, order)
          end
        end
        builder
      end

      # returns the order of the processing method
      def order(processing_method)
        processing_methods.index(processing_method)
      end

      def self.from_xml(xml, link)
        processing_methods = xml.children.map do |pm_n| 
          ProcessingMethod.new(link[:software_hash][xml[:softwareRef]])
            .describe_self_from_xml!(pm_n, link[:ref_hash])
        end
        self.new(xml[:id], processing_methods)
      end

    end
  end
end
