require 'mspire/mzml/list'

module Mspire
  class Mzml
    class DataProcessing
      extend Mspire::Mzml::List

      attr_accessor :id, :processing_methods

      # yields self if given a block
      def initialize(id, processing_methods=[], &block)
        @id, @processing_methods = id, processing_methods
        block.call(self) if block
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

      def self.from_xml(xml, ref_hash, software_hash)
        processing_methods = xml.children.map do |pm_n| 
          ProcessingMethod.from_xml(pm_n, ref_hash, software_hash)
        end
        self.new(xml[:id], processing_methods)
      end

    end
  end
end
