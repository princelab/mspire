require 'ms/msrun'
require 'fileutils'

module MS; end

module MS::Parser::MzXML
  Base_dir_for_parsers = 'ms/parser/mzxml'
  # inherits XMLStyleParser and version
  include MS::Parser
  include XMLStyleParser

  # warning: clobbers file unless a newfilename is provided!
  # returns the output filename
  # will fix any size file!
  def self.fix_bad_scan_tags(filename, newfilename=nil)

    out_io = 
      if newfilename
        File.open(newfilename, 'w')
      else
        Tempfile.new(File.basename(filename))
      end
    File.open(filename) do |fh|
      self.fix_bad_scan_tags_from_io(fh, out_io)
    end
    out_io.close
    unless newfilename
      FileUtils.mv out_io.path, filename
    end
  end

  # this is a memory efficient method to fix bad scan tags
  # prints cleaned up file to out_io
  # no effort is made to rewind the io objects, the user must do this if they
  # plan to continue using these objects!
  def self.fix_bad_scan_tags_from_io(io, out_io)
    regexp = /<\/scan>/ 
    end_scan_line = false

    io.each("\n") do |line|
      if end_scan_line && line =~ regexp
        # two end scan lines! # don't print to out_io
        end_scan_line = true
      elsif line =~ regexp
        out_io.print(line)
        end_scan_line = true
      else
        out_io.print(line)
        end_scan_line = false
      end
    end
  end

  # returns a string with double </scan></scan> tags into single and missing
  # </scan> tags after peaks added in
  # we do this in windows style since these are generated off a windows
  # machine only
  #def self.fix_bad_scan_tags(string)
  #  string.gsub(/<\/scan>\s+<\/scan>/m, '</scan>').gsub(/<\/peaks>\s+<scan/m, "</peaks>\r\n  </scan>\r\n  <scan")
  #end

  # returns true if it has the bad tag
  def self.has_bad_scan_tag_from_string?(string)
    if string.match(/<\/scan>\s+<\/scan>/m)
      true
    else
      false
    end
  end

  def self.has_bad_scan_tag?(filename)
    File.open(filename) do |fh|
      self.has_bad_scan_tag_from_io?(fh)
    end
  end

  # very efficient algorithm to check for malformed xml typical of readw
  # output. The extra closing scan tags come after the last ms/ms scan in a
  # cycle rewinds the io after looking
  def self.has_bad_scan_tag_from_io?(io)
    seen_first_ms_level = false
    seen_higher_ms_level = false
    cur_ms_level = 0
    found_double_end_tag = false
    found_end_tag = false
    io.each("\n") do |line|
      if line =~ /<\/scan>/
        if found_end_tag  # already found one!
          found_double_end_tag = true
          break
        end
        found_end_tag = true
      else
        found_end_tag = false
      end

      if line =~ /msLevel="(\d+)"/
        cur_ms_level = $1.dup
        if seen_first_ms_level && seen_higher_ms_level && cur_ms_level == '1'
          break
        end
        if cur_ms_level == '1'
          seen_first_ms_level = true
        elsif cur_ms_level == '2'
          seen_higher_ms_level = true
        end
      end
    end
    io.rewind
    found_double_end_tag
  end

  # returns a specific parser MS::Parser::MzXML::#{ParserType}
  # based on choose_parser from xml_style_parser
  def self.new(parse_type=:msrun, version='1.0', opts={})
    special_subclass = 
      if opts[:lazy] == :io
      'LazyPeaks'
      else ; nil
      end
    @version = version
    @method = parse_type
    XMLStyleParser.require_parse_files(Base_dir_for_parsers)
    parser_class = XMLStyleParser.choose_parser(self, parse_type, special_subclass)
    parser = parser_class.new(parse_type, version)
  end

  # Returns an array of scans indexed by scan number
  # NOTE that the first scan (zero indexed) will likely be nil!
  # accepts an optional parse_type = 'xmlparser' | 'rexml'
  def scans_by_num(mzXML_file, parse_type=nil)
    unless parse_type
      parse_type = default_parser
    end
    scans = []
    case parse_type
    when 'xmlparser' 
      parser = MS::MzXML::XMLParser::TimeMzIntenIndexer.new
      parser.parse(IO.read(mzXML_file))
      scans = parser.scans_by_num
    when 'rexml' # use REXML
      # This is really too slow for files of this size
      doc = REXML::Document.new File.new(mzXML_file)
      doc.elements.each('msRun/scan') do |scan|
        rt = scan.attributes['retentionTime']  ## like PT0.154000S"
        level = scan.attributes['msLevel']
        to_print = []
        prec_mz = nil
        prec_int = nil
        if level.to_i != 1
          scan.elements.each("precursorMz") do |prec|
            prec_mz = prec.text.to_f
            prec_int = prec.attributes["precursorIntensity"].to_f
          end
        end
        # remove the leading PT and trailing S on the retention time!
        rt = rt[2...-1]

        num = scan.attributes['num'].to_i
        scans[num] = MS::Scan.new(num, scan.attributes['msLevel'].to_i, rt.to_f, prec_mz, prec_int) 
      end #doc.elements
    else
      throw ArgumentError, "invalid parse type: #{parse_type}"
    end
    ## update the scans for parents
    MS::Scan.add_parent_scan(scans)
    scans
  end

  # Returns a Hash indexed by filename (with no extension) for a given path
  # extension = glob (string) or regex
  # The basename is given as: file.split('.').first
  def precursor_mz_by_scan_for_path(path, extension, parse_type=nil)
    hash = {}
    Dir.chdir path do
      files = []
      if extension.class == String
        files = Dir[extension]
      elsif extension.class == Regexp
        files = Dir.entries(".").find_all do |dir|
          dir =~ extension
        end
      else
        puts "extension: #{extension} not a String or Regexp!"
      end
      files.each do |file|
        base = file.split('.').first
        hash[base] = precursor_mz_by_scan(file, parse_type)
      end
    end
    hash
  end

  # Returns hash where hash[scan_num] = [precursorMz, precursorIntensity]
  # Parent scans are not hashed
  # Keys and values are both strings
  def precursor_mz_and_inten_by_scan(file)
    # in progress
  end

  # Returns array where array[scan_num] = precursorMz
  # precursorMz are Floats
  # Array index likely starts at 1!
  def precursor_mz_by_scan_num(file)
    ## THIS SHOULD BE CREATED IN specific XML LIBS
  end

  # Returns a hash of basic info on an mzXML run:
  #   *mzXML_elemt*   *hash keys (symbols)*
  #   scanCount       scan_count
  #   startTime       start_time
  #   endTime         end_time
  #   startMz         start_mz
  #   endMz           end_mz
  def basic_info(mzxml_file)
    puts "parsing: #{mzxml_file} #{File.exist?(mzxml_file)}" if $VERBOSE
    hash = {}
    scan_count_tmp = []
    (1..5).to_a.each do |n| scan_count_tmp[n] = 0 end
    @fh = File.open(mzxml_file)
    @line = ""
    scan_count_tmp[0] = _el("scanCount").to_i
    hash[:start_time] = _el("startTime").sub(/^PT/, "").sub(/S$/,"").to_f
    hash[:end_time] = _el("endTime").sub(/^PT/, "").sub(/S$/,"").to_f
    hash[:ms_level] = _el("msLevel").to_i
    scan_count_tmp[1] = 1
    if hash[:ms_level] == 1
      hash[:start_mz] = _el("startMz").to_f
      hash[:end_mz] = _el("endMz").to_f
    end

    while !@fh.eof?
      @line = @fh.readline 
      ms_level = _el("msLevel")
      if ms_level
        scan_count_tmp[ms_level.to_i] += 1
      else
        break
      end
    end
    scan_count = []
    scan_count_tmp.each do |cnt|
      if cnt != 0
        scan_count.push cnt
      else
        break
      end
    end
    hash[:scan_count] = scan_count
    @fh.close
    hash
  end
  
  # returns [start_mz, end_mz] of the first full scan (ms_level == 1)
  def start_and_end_mz(mzxml_file)
    @fh = File.open(mzxml_file)
    ms_level = 0
    @line = ""
    while ms_level != 1
      ms_level = _el("msLevel").to_i
    end
    start_mz = _el("startMz").to_f
    end_mz = _el("endMz").to_f
    @fh.close
    [start_mz, end_mz]
  end

  def _el(name)
    re = /#{name}="(.*)"/
    while @line !~ re && !@fh.eof?
      @line = @fh.readline
    end
    if $1
      return $1.dup
    else
      return nil
    end
  end

end


