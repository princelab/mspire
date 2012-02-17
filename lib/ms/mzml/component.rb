require 'ms/cv/describable'

module MS
  class Mzml
    module Component
      include Describable
      attr_accessor :order

      def to_xml(builder)
        klass = class.to_s
        klass[0] = klass[0].downcase
        builder.send(klass, order: @order)
        super(builder)
      end

      def self.list_xml(components, builder)
        builder.componentList(count: components.size) do |comp_n|
          components.each {|component| component.to_xml(comp_n) }
        end
        builder
      end
    end
  end
end
