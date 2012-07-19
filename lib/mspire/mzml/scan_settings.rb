require 'mspire/mzml/list'
require 'mspire/cv/paramable'

module Mspire
  class Mzml
    class ScanSettings
      include Mspire::CV::Paramable
      extend Mspire::Mzml::List

      attr_accessor :id

      def initialize(id)
        @id = id
        params_init
        yield(self) if block_given?
      end

      def to_xml(builder)
        builder.scanSettings( id: @id ) do |ss_n|
          super(ss_n)
        end
        builder
      end

    end
  end
end
