require 'mspire/cv/paramable'
require 'mspire/mzml/list'

module Mspire
  class Mzml
    class Sample
      include Mspire::CV::Paramable

      attr_accessor :id, :name

      def initialize(id, name, opts={params: []}, &block)
        @id, @name = id, name
        describe_many!(opts[:params])
        block.call(self) if block
      end

      def to_xml(builder)
        builder.sample( id: @id, name: @name ) do |sample_n|
          super(sample_n)
        end
        builder
      end

      extend(Mspire::Mzml::List)
    end
  end
end
