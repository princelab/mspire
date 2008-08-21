
require 'ms/parser/mzxml/dom'

class MS::Parser::MzXML::LibXML < MS::Parser::MzXML::DOM
  def get_root_node_from_string(string)
    XML::Parser.string(string).parse.root
  end
  def get_root_node_from_file(file)
    XML::Parser.filename(file).parse.root
  end
  def get_root_node_from_io(io)
    XML::Parser.io(io).parse.root
  end

end




