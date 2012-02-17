
module MS
  class Mzml
    class Writer
      NAMESPACE = {
        :xmlns => "http://psi.hupo.org/ms/mzml",
        "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance", 
        "xmlns:xsd" => "http://www.w3.org/2001/XMLSchema", 
      }
      MZML_VERSION = '1.1'

      # a hash of namespace information
      attr_accessor :namespace
      attr_accessor :version

      def initialize(namespace=NAMESPACE, version=MZML_VERSION)
        @namespace, @version = namespace, version
      end

      # if given an xml builder object, it will build on that and return it
      # otherwise, it will generate a builder object, hand it to the user in a
      # block and return the xml as a string.
      def to_xml(builder=nil, &block)
        b = builder || Nokogiri::XML::Builder.new
        b.doc.encoding = 'ISO-8859-1'
        b.mzML( namespace.merge( { version: version } ), &block )
        builder ? b : b.to_xml 
      end
    end
  end
end

