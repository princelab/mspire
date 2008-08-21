
class MS::Parser::MzData::LibXML < MS::Parser::MzData::DOM
  def get_root_node_from_file(file)
    XML::Document.file(file).root
  end
end

