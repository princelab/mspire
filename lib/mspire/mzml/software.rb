require 'mspire'
require 'mspire/mzml/list'
require 'mspire/cv/paramable'

module Mspire
  class Mzml
    class Software
      include Mspire::CV::Paramable

      attr_accessor :id, :version

      def initialize(id='mspire', version=Mspire::VERSION, opts={params: []}, &block)
        @id, @version = id, version
        describe_many!(opts[:params])
        block.call(self) if block
      end

      def to_xml(builder)
        builder.software( id: @id, version: @version) do |sf_n|
          super(sf_n)
        end
        builder
      end

      extend(Mspire::Mzml::List)
    end
  end
end
