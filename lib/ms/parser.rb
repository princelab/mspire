require 'xml_style_parser'

module MS; end

module MS::Parser
  # inherits attr_accessor :method, :default_parser, and parse (which should
  # be overridden)
  include XMLStyleParser 

  Mzxml_regexp = /http:\/\/sashimi.sourceforge.net\/schema(_revision)?\/([\w\d_\.]+)/o
  # 'http://sashimi.sourceforge.net/schema/MsXML.xsd' # version 1
  # 'http://sashimi.sourceforge.net/schema_revision/mzXML_X.X' # others
  Mzdata_regexp = /<mzData.*version="([\d\.]+)"/m

  attr_accessor :version

  ############################################
  # POINTERS (to create META MAGIC)
  ############################################
  
  @@filetypes_to_upcase = {
    :mzxml => 'MzXML',
    :mzdata => 'MzData',
    :mzml => 'MzML',
    :raw => 'Raw',
  }

  @@filetypes_to_require = {}
  @@filetypes_to_constant = {}

  abbrevs = Dir.chdir(File.dirname(__FILE__) + "/parser") do
    Dir["*.rb"].map {|f| f.sub(/\.rb$/,'') }
  end
  abbrevs.each do |abbr|
    abb = abbr.to_sym
    req = ['ms', 'parser', abbr].join("/")
    @@filetypes_to_require[abb] = req
    @@filetypes_to_constant[abb] = ['MS', 'Parser', @@filetypes_to_upcase[abb]].join("::")
  end

  ############################################
  # END POINTERS
  ############################################

  # finds the filetype of a file (expects to be at the beginning) and rewinds
  # the filehandle to the beginning returns [filetype, version].  nil if
  # filetype and version could not be determined
  def self.filetype_and_version(fh_or_filename)
    if fh_or_filename.is_a? IO
      fh = fh_or_filename
      found = nil
      # Test for RAW file:
      header = fh.read(18).unpack('@2axaxaxaxaxaxaxa').join
      if header == 'Finnigan'
        return [:raw, nil]
      end
      fh.rewind
      while (line = fh.gets)
        found = 
          case line
          when Mzxml_regexp
            mtch = $2.dup
            case mtch
            when /mzXML_([\d\.]+)/
              [:mzxml, $1.dup]
            when /MsXML/
              [:mzxml, '1.0']
            else
              abort "Cannot determine mzXML version!"
            end
          when Mzdata_regexp
            [:mzdata, $1.dup]
          end
        if found
          break
        end
      end
      fh.rewind
      found
    else
      File.open(fh_or_filename) do |fh|
        filetype_and_version(fh)
      end
    end
  end

  # filetype_version is an example file to parse, or it is an array: [type, version].
  # parse_type is the information to be gleaned (as symbol).
  def self.new(filetype_version, parse_type, opts={})
    unless filetype_version.is_a? Array
      filetype_version = filetype_and_version(filetype_version)
    end
    require_and_create_parser(filetype_version, parse_type, opts)
  end

  private 

  # returns a working parser.
  def self.require_and_create_parser(filetype_version, parse_type, opts)
    (filetype, version) = filetype_version
    #puts "FT: #{filetype} VERSION: #{version}"
    reply = require @@filetypes_to_require[filetype]
    @@filetypes_to_require[filetype]
    parser_class = MS::Parser.const_get(@@filetypes_to_upcase[filetype])
    parser_class.new(parse_type, version, opts)
  end

end
