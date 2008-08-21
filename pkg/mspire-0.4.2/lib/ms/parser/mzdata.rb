require 'ms/msrun'

module MS; end

module MS::Parser::MzData
  Base_dir_for_parsers = 'ms/parser/mzdata'

  # inherits XMLStyleParser and version
  include MS::Parser
  include XMLStyleParser
 
  # returns a specific parser MS::Parser::MzXML::#{ParserType}
  # based on choose_parser from xml_style_parser
  def self.new(parse_type=:msrun, version='1.05', opts={})
    special_subclass = 
      if opts[:lazy] == :io
      'LazyData'
      else ; nil
      end

    @version = version
    @method = parse_type
    #p self.methods.grep /choose_parser/
    XMLStyleParser.require_parse_files(Base_dir_for_parsers)
    parser_class = XMLStyleParser.choose_parser(self, parse_type, special_subclass)
    parser = parser_class.new(parse_type, version)
  end

end


