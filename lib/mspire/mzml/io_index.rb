require 'mspire/mzml/parser'

module Mspire
  class Mzml

    # an index that retrieves its objects on the fly by index from the IO object.
    class IOIndex
      include Enumerable

      attr_reader :io

      attr_reader :byte_index

      # byte_index will typically be an Mspire::Mzml::Index object.
      def initialize(io, byte_index, ref_hash)
        @io, @byte_index, @ref_hash = io, byte_index, ref_hash
        @object_class = Mspire::Mzml.const_get(@byte_index.name.to_s.capitalize)
        @closetag_regexp = %r{</#{name}>}
      end

      def name
        @byte_index.name
      end

      def each(&block)
        return enum_for(__method__) unless block
        (0...byte_index.size).each do |int|
          block.call(self[int])
        end
      end

      def [](index)
        @object_class.from_xml(fetch_xml_node(index), @ref_hash)
      end

      def length
        @byte_index.length
      end
      alias_method :size, :length

      # gets the data string through to last element
      def get_xml_string(start_byte)
        @io.seek(start_byte)
        data = ""
        @io.each_line do |line|
          data << line 
          break if @closetag_regexp.match(line)
        end
        data
      end

      def xml_node_from_start_byte(start_byte)
        xml = get_xml_string(start_byte)
        Nokogiri::XML.parse(xml, nil, @encoding, Parser::NOBLANKS).root
      end

      def fetch_xml_node(index)
        xml_node_from_start_byte(byte_index[index])
      end

    end
  end
end
