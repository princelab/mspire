require 'mspire/mzml/list'

module Mspire
  class Mzml
    class DataProcessing

      attr_accessor :id, :processing_methods

      # yields self if given a block
      def initialize(id, processing_methods=[], &block)
        @id, @processing_methods = id, processing_methods
        block.call(self) if block
      end

      def to_xml(builder)
        builder.dataProcessing( id: @id ) do |dp_n|
          processing_methods.each do |proc_method|
            proc_method.to_xml(dp_n)
          end
        end
        builder
      end

      def self.from_xml(xml, ref_hash, software_hash)
        processing_methods = xml.children.map do |pm_n| 
          ProcessingMethod.from_xml(pm_n, ref_hash, software_hash)
        end
        self.new(xml[:id], processing_methods)
      end

      extend(Mspire::Mzml::List)
    end
  end
end
