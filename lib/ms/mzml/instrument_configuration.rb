require 'ms/cv/describable'
require 'ms/mzml/component'

module MS
  class Mzml
    class InstrumentConfiguration
      include MS::CV::Describable

      # (required) the id that this guy can be referenced from
      attr_accessor :id

      # a list of Source, Analyzer, Detector objects
      attr_accessor :components

      # a single software object associated with the instrument
      attr_accessor :software

      def initialize(id, components=[])
        @id = id
        @components = components
      end

      def to_xml(builder)
        builder.instrumentConfiguration(id: @id) do |inst_conf_n|
          super(builder)
          MS::Mzml::Component.list_xml(components, inst_conf_n)
          inst_conf_n.softwareRef(ref: @software.id) if @software
        end
        builder
      end
    end
  end
end
