require 'mspire/cv/paramable'
require 'mspire/mzml/list'

module Mspire
  class Mzml
    class Sample
      include Mspire::CV::Paramable

      # A unique identifier across the samples with which to reference this sample description.
      attr_accessor :id

      # An optional name for the sample description, mostly intended as a quick mnemonic.
      attr_accessor :name

      def initialize(id, opts={params: []}, &block)
        @id = id
        super(opts)
        block.call(self) if block
      end

      def to_xml(builder)
        builder.sample( id: @id, name: @name ) do |sample_n|
          super(sample_n)
        end
        builder
      end

      def self.from_xml(xml, ref_hash)
        obj = self.new(xml[:id])
        obj.name = xml[:name]
        describe!(xml, ref_hash)
      end

      extend(Mspire::Mzml::List)
    end
  end
end
