require 'mspire/mzml/list'
require 'mspire/cv/paramable'

module Mspire
  class Mzml
    class ScanSettings
      include Mspire::CV::Paramable

      attr_accessor :id

      def initialize(id, opts={params: []}, &block)
        @id = id
        describe!(*opts[:params])
        block.call(self) if block
      end

      def to_xml(builder)
        builder.scanSettings( id: @id ) do |ss_n|
          super(ss_n)
        end
        builder
      end

      extend(Mspire::Mzml::List)

    end
  end
end
