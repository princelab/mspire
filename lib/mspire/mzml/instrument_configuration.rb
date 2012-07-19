require 'mspire/cv/paramable'
require 'mspire/mzml/component'
require 'mspire/mzml/list'

module Mspire
  class Mzml
    class InstrumentConfiguration
      include Mspire::CV::Paramable
      extend Mspire::Mzml::List

      # (required) the id that this guy can be referenced from
      attr_accessor :id

      # a list of Source, Analyzer, Detector objects (optional)
      attr_accessor :components

      # a single software object associated with the instrument (optional)
      attr_accessor :software

      def initialize(id, components=[])
        @id, @components = id, components
        params_init
        yield(self) if block_given?
      end

      def to_xml(builder)
        builder.instrumentConfiguration(id: @id) do |inst_conf_n|
          super(builder)
          Mspire::Mzml::Component.list_xml(components, inst_conf_n)
          inst_conf_n.softwareRef(ref: @software.id) if @software
        end
        builder
      end

      def self.from_xml(xml, link)
        obj = self.new(xml[:id])
        next_n = obj.describe_from_xml!(xml, link[:ref_hash])
        if next_n.name == 'componentList'
          obj.components = next_n.children.map do |component_n|
            Mspire::Mzml.const_get(component_n.name.capitalize).new.describe_self_from_xml!(component_n, link[:ref_hash])
          end
          next_n = next_n.next
        end
        if next_n.name == 'softwareRef'
          obj.software = link[:software_hash][next_n[:ref]]
        end
        obj
      end

    end
  end
end
