require 'mspire/mzml/parser'

module Mspire
  class Mzml

    # an index that retrieves its objects by index or id
    class IOIndex
      include Enumerable

      attr_reader :io

      attr_reader :byte_index

      # byte_index will typically be an Mspire::Mzml::Index object
      def initialize(io, byte_index)
        @io = io
        @byte_index = byte_index
        @object_class = Mspire::Mzml.const_get(@byte_index.name.to_s.capitalize)
      end

      def name
        @byte_index.name
      end

      def each
        block || return enum_for(__method__)
        (0...byte_index.size).each do |int|
          block.call(fetch(int))
        end
      end

      # gets the data string string up until 
      def get_xml_string(start_byte)
        @io.seek(start_byte)
        data = ""
        regexp = %r{</#{@byte_index.name}>}
        @io.each_line do |line|
          data << line 
          break if regexp.match(line)
        end
        data
      end

      def length
        @byte_index.length
      end
      alias_method :size, :length

      def xml_node_from_start_byte(start_byte)
        xml = get_xml_string(start_byte)
        Nokogiri::XML.parse(xml, nil, @encoding, Parser::NOBLANKS).root
      end

      def fetch_xml_node(index_or_id)
        xml_node_from_start_byte(byte_index.start_byte(index_or_id))
      end

      def fetch(index_or_id)
        @object_class.from_xml(fetch_xml_node(index_or_id))
      end

      alias_method :[], :fetch

    end
  end
end
