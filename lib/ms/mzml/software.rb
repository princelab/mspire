require 'mspire'
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
        builder.software( id: @id, name: @name, location: @location ) do |sf_n|
          super(sf_n)
        end
        builder
      end

      # creates softwareList xml
      def list_xml(software_objs, builder)
        software_objs.each {|software| software.to_xml(builder) }
        builder
      end
    end
  end
end
