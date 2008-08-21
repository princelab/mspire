require 'ms/parser/mzdata/dom'

class MS::Parser::MzData::AXML < MS::Parser::MzData::DOM
  def get_root_node_from_file(file)
    ::AXML.parse_file(file)
  end
  def get_root_node_from_io(io)
    ::AXML.parse(io)
  end
end

class MS::Parser::MzData::AXML::LazyData < MS::Parser::MzData::AXML
  def get_root_node_from_string(string)
    ::AXML::LazyData.parse(string)
  end
  def get_root_node_from_file(file)
    ::AXML::LazyData.parse_file(file)
  end
  def get_root_node_from_io(io)
    ::AXML::LazyData.parse(io)
  end
end

class AXML::LazyData < AXML
  # Returns the root node (as Element) or nodes (as Array)
  def self.parse(stream)
    parser = ::AXML::XMLParser::LazyData.new
    parser.parse(stream)
    parser.root
  end
end

# This parser stores information about where the data (peaks) information is
# in the file
# The content of the data node is an array where the first member is the
# start index and the last member is the number of bytes.  All other members
# should be ignored.
class AXML::XMLParser::LazyData < ::AXML::XMLParser

  def startElement(name, attributes)
    text =
      if name == 'data' ; []
      else ; ''
      end
    new_el = ::AXML::El.new(@cur, name, attributes, text, [])
    # add the new node to the previous parent node
    @cur.add_node(new_el)
    # notice the change in @cur node
    @cur = new_el
  end

  def character(data)
    if @cur.text.is_a? Array
      @cur.text << byteIndex
    else
      @cur.text << data
    end
  end

  def endElement(name)
    if @cur.text.is_a? Array
      @cur.text << (byteIndex - @cur.text.first)
    end
    @cur = @cur.parent
  end

end
