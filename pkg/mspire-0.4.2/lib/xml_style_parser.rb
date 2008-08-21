
module XMLStyleParser
  @done_once = nil
  
  Parser_precedence = %w(AXML LibXML XMLParser Regexp REXML)
  # currently AXML requires 'xmlparser' to be installed.... (may not always be
  # the case...)
  File_required = {'AXML' => /^axml/, 'LibXML' => /^xml\/libxml/, 'XMLParser' => /^xmlparser/}

  # the method that the parser will call on the given file at parse!
  attr_accessor :method

  # parses the given file by sending to @method
  def parse(file, opts={})
    if respond_to? @method
      send(@method, file, opts)
    else
      raise NoMethodError, "Parser of class #{self.class} can't parse #{@method} yet"
    end
  end

  # XMLParser and xml/libxml are incompatible, so if xmlparser is available,
  # libxml will not be loaded (XMLParser#parse is clobbered by
  # XML::Parser#parse [don't ask me why])
  def self.require_parsers
    if !@done_once
      have_xmlparser = false
      begin
        require 'xmlparser'
        puts "Loaded XMLParser" if $VERBOSE
        have_xmlparser = true
      rescue LoadError
      end

      begin
        require 'axml'
        puts "Loaded AXML" if $VERBOSE
      rescue LoadError
      end

      begin
        unless have_xmlparser
          require 'xml/libxml'
          puts "Loaded xml/libxml" if $VERBOSE
          ################################################################
          # IMPORTANT!
          # This magic line makes the parser behave like it ought to!!
          XML::Parser.default_keep_blanks = false
          ################################################################
        end
      rescue LoadError
      end
    end
    @done_once = true
  end

  # returns an array of strings depending on File_required (in the order of
  # Parser_precedence)
  def self.available_xml_parsers
    require_parsers  
    parser_precedence = Parser_precedence.dup
    File_required.map do |k,v|
      unless $".any? {|req_file| req_file.match(v) }
        parser_precedence.delete(k) 
      end
    end
    parser_precedence
  end

  ## appends downcase to each parser type here and tries to require it
  # returns all those that were required without a load error
  def self.require_parse_files(base_dir)
    XMLStyleParser.available_xml_parsers.select do |v| 
      to_require = base_dir + '/' + v.downcase
      begin 
        require to_require
        true
      rescue LoadError
        false
      end
    end
  end

  # seeks a subclass that has the public_method @method
  def self.choose_parser(const, method, special_subclass=nil)
    ## First update @@parser_precedence to ensure we should get these guys
    parser_precedence = available_xml_parsers

    available_constants = parser_precedence.select do |v| 
      const.const_defined?(v)
    end
    available_subclasses = available_constants.map do |v|
      const.const_get(v)
    end
    available = available_subclasses.select do |subclass|
      subclass.public_method_defined? method
    end
    if special_subclass
      available_special_subclasses = []
      available.each do |subclass|
        if subclass.const_defined?(special_subclass)
          available_special_subclasses << subclass.const_get(special_subclass)
        end
      end
      available = available_special_subclasses
    end
    if available.size > 0
      available.first
    else
      warning = ""
      if special_subclass
        warning << "** while looking for special subclass: #{special_subclass} **\n"
      end
      warning << "No parser of class #{const} can parse :#{method}\n** Is 'axml' (or another xml parser) installed and working? **"
      raise NoMethodError, warning
    end
  end

end
