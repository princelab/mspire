require 'mspire/cv/paramable'
require 'mspire/mzml/list'

module Mspire
  class Mzml
    # order is not an intrinsic property of this object, so it 
    module Component
      include Mspire::CV::Paramable
      # using custom list_xml, so no extend Mspire::Mzml::List

      def initialize
        params_init
        yield(self) if block_given?
      end

      def to_xml(builder, order)
        klass = self.class.to_s.split('::').last
        klass[0] = klass[0].downcase
        builder.tag!(klass, order: order) do |c_n|
          super(c_n)
        end
        builder
      end

      def self.list_xml(components, builder)
        builder.componentList(count: components.size) do |xml_n|
          components.each_with_index do |component, order|
            component.to_xml(xml_n, order)
          end
        end
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
