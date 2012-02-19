require 'mspire'
require 'ms/mzml/list'
require 'ms/cv/describable'

module MS
  class Mzml
    class Software
      include MS::CV::Describable

      attr_accessor :id, :version

      def initialize(id='mspire', version=Mspire::VERSION, *params, &block)
        @id, @version = id, version
        super(*params, &block)
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
