require 'mspire/cv/paramable'
require 'mspire/mzml/list'

module Mspire
  class Mzml
    class Sample
      include Mspire::CV::Paramable
      extend Mspire::Mzml::List

      # A unique identifier across the samples with which to reference this sample description.
      attr_accessor :id

      # An optional name for the sample description, mostly intended as a quick mnemonic.
      attr_accessor :name

      def initialize(id)
        @id = id
        params_init
        yield(self) if block_given?
      end

      def to_xml(builder)
        builder.sample( id: @id, name: @name ) do |sample_n|
          super(sample_n)
        end
        builder
      end

      def self.from_xml(xml, link)
        obj = self.new(xml[:id])
        obj.name = xml[:name]
        obj.describe_self_from_xml!(xml, link[:ref_hash])
      end

    end
  end
end
