require 'mspire'
require 'ms/mzml/list'
require 'ms/cv/paramable'

module MS
  class Mzml
    class Software
      include MS::CV::Paramable

      attr_accessor :id, :version

      def initialize(id='mspire', version=Mspire::VERSION, opts={params: []}, &block)
        @id, @version = id, version
        describe!(*opts[:params])
        block.call(self) if block
      end

      def to_xml(builder)
        builder.software( id: @id, version: @version) do |sf_n|
          super(sf_n)
        end
        builder
      end

      extend(MS::Mzml::List)
    end
  end
end
