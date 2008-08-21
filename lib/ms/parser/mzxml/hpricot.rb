
require 'xml_style_parser'
require 'ms/spectrum'
require 'ms/scan'


class MS::Parser::MzXML::Hpricot
  include XMLStyleParser
  include MS::Parser::MzXML

  @@scan_atts = %w(num msLevel retentionTime startMz endMz precursor spectrum)

  def initialize(parse_type=:msrun, version='1.0')
    @method = parse_type
    @version = version
  end

  def new_scan_from_hash(node)
    scan = MS::Scan.new  # array class creates one with 9 positions
    scan[0] = node['num'].to_i
    scan[1] = node['msLevel'].to_i
    scan[2] = node['retentionTime'][2...-1].to_f
    if x = node['startMz']
      scan[3] = x.to_f
      scan[4] = node['endMz'].to_f
    end
    scan
  end

  # takes a scan node and creates a scan object
  # the parent scan is the one directly above it in mslevel
  # if the 
  def create_scan(scan_n, scans_by_num, get_spectra=true)
    if @version < '3.0'
      scan = new_scan_from_hash(scan_n)
      precs = []
      scan_n.each_child do |node|
        case node.name
        when 'precursorMz'
          # should be able to do this!!!
          #scan[5] = scan_n.find('child::precursorMz').map do |prec_n|
          prec = MS::Precursor.new
          prec[1] = node['precursorIntensity'].to_f
          prec[0] = node.content.to_f
          if x = node['precursorScanNum']
            prec[2] = scans_by_num[x.to_i]
          end
          precs << prec
        when 'peaks'
          next unless get_spectra
          # SHOULD be able to do this!!
          #peaks_n = scan_n.find_first('child::peaks')
          scan[6] = MS::Spectrum.from_base64_peaks(node.content, node['precision'].to_i)
        end
      end
      scan[5] = precs
      scan
    else  # for version > 3.0 
      abort 'not supporting version 3.0 just yet'
      # note that mzXML version 3.0 *can* have more than one peak...
      # I'm not sure how to deal with that since I have one spectrum/scan
    end
  end


  # returns an array of msrun objects
  def msruns(file)
    raise NotImplementedError
  end

  # returns a string with double </scan></scan> tags into single and missing
  # </scan> tags after peaks added in
  # we do this in windows style since these are generated off a windows
  # machine only
  def fix_bad_scan_tags(file)
    IO.read(file).gsub(/<\/scan>\s+<\/scan>/m, '</scan>').gsub(/<\/peaks>\s+<scan/m, "</peaks>\r\n  </scan>\r\n  <scan")
  end

  # right now cannot parse multiple runs out of an mzXML version 2 file since
  # this is built around a single run per file
  # OPTIONS:
  #   :msrun => MSRun    # use this object instead of creating one
  #   :spectra => *true|false   # if false don't get spectra
  def msrun(file, opts={})
    unless opts.key?(:spectra)
      opts[:spectra] = true
    end

    msrun_obj = 
      if x = opts[:msrun]
        msrun_obj = x
      else
        MS::MSRun.new
      end

    doc = File.open(file) {|fh| ::Hpricot.XML(fh) }
      #if @version == '2.0'
      #  # may not be necessary in hpricot!
      #  #string = fix_bad_scan_tags(file)
      #  #XML::Parser.string(string).parse
      #else
      #  XML::Document.file(file)
      #end
    msrun_n = doc.at('msRun')

    ## HEADER
    scan_count = msrun_n['scanCount'].to_i
    msrun_obj.scan_count = scan_count
    scans_by_num = Array.new(scan_count + 1)
    
    ## SPECTRUM
    parent = nil
    scans = Array.new( scan_count )
    scn_index = 0

    # we should be able to do this, but it's not working!!!
    #scan_n = msrun_n.find_first('scan')
    #while (scn_index < scan_count)
    get_spectra = opts[:spectra]

    msrun_n.each_child do |scan_n|
      p scan_n 
      abort

      next unless scan_n.name == 'scan'
      scan = create_scan(scan_n, scans_by_num, get_spectra)
      scans[scn_index] = scan
      sc = scan_n.next
      scans_by_num[scan[0]] = scan 
      scn_index += 1
    end


    ## update the scan's parents
    MS::MSRun.add_parent_scan(scans)

    # note that startTime and endTime are optional AND in >2.2 are dateTime
    # instead of duration types!, so we will just use scan times...
    # Also, note that startTime and endTime are BROKEN on readw -> mzXML 2.0
    # export.  They give the start and end time in seconds, but they are
    # really minutes.  All the more reason to use the first and last scans!
    msrun_obj.start_time = scans.first.time
    msrun_obj.end_time = scans.last.time

    msrun_obj.scans = scans
  end

end



=begin
## THIS IS THE SAX PARSER VERSION.  IT NEEDS A BIT OF BRUSH UP AND IT WOULD
## WORK.  I THINK THE default guy is probably faster

  def msrun(file, msrun_obj)
    # Figure out where the first scan is at in the file:
    pos_after_first_scan = nil
    File.open(file) do |fh|
      fh.each do |line|
        if line =~ /<scan/
          pos_after_first_scan = fh.pos
        end
      end
    end

    # Get only the header:
    header_string = IO.read(file, pos_after_first_scan)

    @msrun_obj = msrun_obj
    # Parse out the header info:
    parser = XML::SaxParser.new
    parser.string = header_string
    parser.on_start_element do |name, attrs|
      if name == 'msRun'
        @msrun_obj.scan_count = attrs['scanCount'].to_i
        @msrun_obj.start_time = attrs['startTime'][2...-1].to_f
        @msrun_obj.end_time = attrs['endTime'][2...-1].to_f
      end
    end
    parser.parse

    
    # Parse the scans out:
    scan_st = 'scan'
    prec_st = 'precursorMz'
    peaks_st = 'peaks'
    prec_inten_st = 'precursorIntensity'
    precision_st = 'precision'

    #parser = MS::Parser::MzXML::Hpricot::SaxParser::MSRun.new
    parser = XML::SaxParser.new
    parser.filename = file
    parser.on_start_document do
      @scans = []
      @current_scan = nil
      @get_peaks = false
      @get_prec_mz = false
    end

    parser.on_characters do |chars|
      if @get_peaks
        @get_peaks << chars
      elsif @get_prec_mz
        @get_prec_mz << chars
      end
    end

    parser.on_end_element do |el|
      case el
      when 'peaks'
        @current_scan.spectrum = Spectrum.from_base64_peaks(@get_peaks, @precision, true)
        @get_peaks = false
      when 'precursorMz'
        @current_scan[5] = [Precursor.new([@get_prec_mz.to_f])]
        @get_prec_mz = false
      end
    end

    parser.on_start_element do |name, attr_hash|
      case name
      when scan_st
        @current_scan = new_scan_from_hash(attr_hash)
        sz = @scans.size 
        @scans << @current_scan
      when prec_st
        @current_scan[5].first[1] = attr_hash[prec_inten_st].to_f
        @get_prec_mz = ''
      when peaks_st
        @precision = attr_hash[precision_st].to_i
        case @version[0,1].to_ip
        when 3
          if ch['pairOrder'] != 'm/z-int' # only version 3.0 has others
            abort "cannot yet read anything but 'm/z-int' pair order"
          end
        end
        @get_peaks = ''
      end
    end
    parser.parse

    @msrun_obj.scans = @scans
    @msrun_obj.scans.each_with_index do |sc,i|
      if sc.spectrum.mz == nil
        abort "INDEX: #{i}"
      end
    end
    @msrun_obj
  end
=end



