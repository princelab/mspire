require 'mspire/cv/paramable'
require 'mspire/mzml/component'
require 'mspire/mzml/list'

module Mspire
  class Mzml
    class InstrumentConfiguration
      include Mspire::CV::Paramable
      extend Mspire::Mzml::List
      extend Mspire::CV::ParamableFromXml

      # (required) the id that this guy can be referenced from
      attr_accessor :id

      # a list of Source, Analyzer, Detector objects
      attr_accessor :components

      # a single software object associated with the instrument
      attr_accessor :software

      def initialize(id, components=[], opts={params: []})
        super(opts)
        @id = id
        @components = components
      end

      def to_xml(builder)
        builder.instrumentConfiguration(id: @id) do |inst_conf_n|
          super(builder)
          Mspire::Mzml::Component.list_xml(components, inst_conf_n)
          inst_conf_n.softwareRef(ref: @software.id) if @software
        end
        builder
      end

      def self.from_xml(xml, ref_hash)
        obj = self.new(xml[:id])
        obj.components = xml.xpath('./componentList').first.children.map do |component_n|
          Mspire::Mzml::Component.from_xml(component_n, ref_hash)
        end
        super(xml, ref_hash, obj)
      end

    end
  end
end
