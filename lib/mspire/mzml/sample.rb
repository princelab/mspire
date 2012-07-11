require 'mspire/cv/paramable'
require 'mspire/mzml/list'

module Mspire
  class Mzml
    class Sample
      include Mspire::CV::Paramable

      attr_accessor :id, :name

      def initialize(id, name, opts={params: []}, &block)
        @id, @name = id, name
        super(opts)
        block.call(self) if block
      end

      def to_xml(builder)
        builder.sample( id: @id, name: @name ) do |sample_n|
          super(sample_n)
        end
        builder
      end

      def self.from_xml(xml)
        WORKING HERE!
        
      end

      extend(Mspire::Mzml::List)
    end
  end
end
