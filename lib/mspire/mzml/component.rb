require 'mspire/cv/paramable'
require 'mspire/mzml/list'

module Mspire
  class Mzml
    module Component
      include Mspire::CV::Paramable
      extend Mspire::Mzml::List
      extend Mspire::CV::ParamableFromXml

      attr_accessor :order

      def initialize(order, opts={params: []})
        @order = order
        super(opts)
      end

      def to_xml(builder)
        builder.component(order: @order) do |c_n|
          super(c_n)
        end
        builder
      end

      def self.from_xml(xml, ref_hash)
        obj = Mspire::Mzml.const_get(xml.name.capitalize).new(xml[:order])
        super(xml, ref_hash, obj)
      end
    end

    class Source
      include Component
    end

    class Analyzer
      include Component
    end

    class Detector
      include Component
    end

  end
end
