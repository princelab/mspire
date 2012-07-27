require 'mspire'
require 'mspire/mzml/list'
require 'mspire/cv/paramable'

module Mspire
  class Mzml
    class Software
      include Mspire::CV::Paramable
      extend Mspire::Mzml::List

      attr_accessor :id, :version

      def initialize(id="mspire_#{Mspire::VERSION}", version=Mspire::VERSION)
        @id, @version = id, version
        params_init
        yield(self) if block_given?
      end

      def to_xml(builder)
        builder.software( id: @id, version: @version) do |sf_n|
          super(sf_n)
        end
        builder
      end

      def self.from_xml(xml, link)
        obj = self.new(xml[:id], xml[:version])
        obj.describe_self_from_xml!(xml, link[:ref_hash])
      end

    end
  end
end
