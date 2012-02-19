
module MS
  class Mzml
    # Methods for simple List objects (scanList, instrumentConfigurationList,
    # etc.)
    module List
      def list_xml_element
        return @list_xml_element if @list_xml_element
        @list_xml_element = self.to_s.split('::').last << "List"
        @list_xml_element[0] = @list_xml_element[0].downcase
        @list_xml_element
      end

      def list_xml(objects, builder, tagname=nil)
        # InstrumentConfiguration -> instrumentConfigurationList
        builder.tag!(tagname || list_xml_element, count: objects.size) do |n|
          objects.each {|obj| obj.to_xml(n) }
        end
        builder
      end
    end
  end
end
