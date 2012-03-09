require 'ms/cv/paramable'
require 'ms/mzml/list'

module MS
  class Mzml
    module Component
      include MS::CV::Paramable

      attr_accessor :order

      def to_xml(builder)
        builder.component(order: @order) do |c_n|
          super(c_n)
        end
        builder
      end

      extend(MS::Mzml::List)
    end
  end
end
