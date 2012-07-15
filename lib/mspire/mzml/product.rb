require 'mspire/mzml/list'

module Mspire
  class Mzml
    # The method of product ion selection and activation in a precursor ion scan
    #
    # this object is NOT paramable, it just contains a single IsolationWindow
    class Product
      
      extend Mspire::Mzml::List

      attr_accessor :isolation_window

      def initialize(isolation_window=nil)
        @isolation_window = isolation_window
      end

      def to_xml(builder)
        builder.product do |p_n|
          @isolation_window.to_xml(p_n) if @isolation_window
        end
      end

      def self.from_xml(xml, ref_hash)
        isolation_window_n = xml.child
        if isolation_window_n
          iw = Mspire::Mzml::IsolationWindow.from_xml(isolation_window_n, ref_hash)
        end
        self.new(iw)
      end

    end
  end
end

