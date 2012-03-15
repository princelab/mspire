require 'mspire/cv/paramable'
require 'mspire/mzml/list'

module Mspire
  class Mzml
    module Component
      include Mspire::CV::Paramable

      attr_accessor :order

      def to_xml(builder)
        builder.component(order: @order) do |c_n|
          super(c_n)
        end
        builder
      end

      extend(Mspire::Mzml::List)
    end
  end
end
