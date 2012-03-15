require 'mspire/mzml/list'

module Mspire
  class Mzml
    class Product
      attr_accessor :isolation_window

      def initialize(isolation_window=nil)
        @isolation_window = isolation_window
      end

      def to_xml(builder)
        builder.product do |p_n|
          @isolation_window.to_xml(p_n) if @isolation_window
        end
      end

      extend(Mspire::Mzml::List)
    end
  end
end

