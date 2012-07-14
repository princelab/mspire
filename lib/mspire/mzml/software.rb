require 'mspire'
require 'mspire/mzml/list'
require 'mspire/cv/paramable'

module Mspire
  class Mzml
    class Software
      include Mspire::CV::Paramable
      extend Mspire::Mzml::List
      extend Mspire::CV::ParamableFromXml

      attr_accessor :id, :version

      def initialize(id='mspire', version=Mspire::VERSION, opts={params: []}, &block)
        @id, @version = id, version
        super(opts)
        block.call(self) if block
      end

      def to_xml(builder)
        builder.software( id: @id, version: @version) do |sf_n|
          super(sf_n)
        end
        builder
      end

      def self.from_xml(xml, ref_hash)
        obj = self.new(xml[:id], xml[:version])
        super(xml, ref_hash, obj)
      end

    end
  end
end
