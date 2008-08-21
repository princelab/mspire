require 'xml_style_parser'
require 'ms/spectrum'
require 'ms/scan'
require 'ms/parser/mzxml'
require 'tempfile'


class MS::Parser::MzXML::DOM
  include XMLStyleParser
  include MS::Parser::MzXML

  NetworkOrder = true

  #@@scan_atts = %w(num msLevel retentionTime startMz endMz precursor spectrum)

  def initialize(parse_type=:msrun, version='1.0')
    @method = parse_type
    @version = version
  end

  def new_scan_from_hash(node)
    scan = MS::Scan.new  # array class creates one with 9 positions
    scan[0] = node['num'].to_i
    scan[1] = node['msLevel'].to_i
    if x = node['retentionTime']
      scan[2] = x[2...-1].to_f
    end
    if x = node['startMz']
      scan[3] = x.to_f
      scan[4] = node['endMz'].to_f
    end
    scan
  end

  # assumes that node contains scans and checks any scan nodes for children
  def add_scan_nodes(nodes, scans, scn_index, scans_by_num, lazy, io)
    nodes.each do |scan_n|
      scan = create_scan(scan_n, scans_by_num, lazy, io)
      scans[scn_index] = scan
      scans_by_num[scan[0]] = scan 
      scn_index += 1
      if @version > '1.0'
        new_nodes = scan_n.find('child::scan')
        if new_nodes.size > 0
          scn_index = add_scan_nodes(new_nodes, scans, scn_index, scans_by_num, lazy, io)
        end
      end
    end
    scn_index
  end

  # takes a scan node and creates a scan object
  # the parent scan is the one directly above it in mslevel
  # lazy must be a symbol from MS::MSRun.new
  def create_scan(scan_n, scans_by_num, lazy, io=nil)
    scan = new_scan_from_hash(scan_n)
    prec = nil
    scan_n.each do |node|
      case node.name
      when 'precursorMz'
        # should be able to do this!!!
        #scan[5] = scan_n.find('child::precursorMz').map do |prec_n|
        raise RuntimeError, "the msrun object can only handle one precursor!" unless prec.nil?
        prec = MS::Precursor.new
        prec[1] = node['precursorIntensity'].to_f
        prec[0] = node.content.to_f
        if x = node['precursorScanNum']
          prec[2] = scans_by_num[x.to_i]
        end
      when 'peaks'
        case lazy
        when :no_spectra
          next
        when :string
          scan[6] = MS::Spectrum::LazyString.from_base64_peaks(node.content, node['precision'].to_i)
        when :io
          # assumes that parsing was done with a LazyPeaks parser!
          nc = node.content
          scan[6] = MS::Spectrum::LazyIO.new(io, nc.first, nc.last, node['precision'].to_i, MS::Parser::MzXML::DOM::NetworkOrder)
        when :not
          # SHOULD be able to do this!!
          #peaks_n = scan_n.find_first('child::peaks')
          scan[6] = MS::Spectrum.from_base64_peaks(node.content, node['precision'].to_i)
        end
      end
    end
    scan[5] = prec
    scan
  end


  # returns an array of msrun objects
  def msruns(file)
    raise NotImplementedError
  end

    # right now cannot parse multiple runs out of an mzXML version 2 file since
  # this is built around a single run per file
  # OPTIONS:
  #   :msrun => (an MSRun object)   # use this object instead of creating one
  #   :lazy => [See MS::MSRun for documentation]
  def msrun(file, opts={})
    #unless opts.key?(:spectra)
    #  opts[:spectra] = true
    #end

    msrun_obj = 
      if x = opts[:msrun]
        msrun_obj = x
      else
        MS::MSRun.new
      end

    io =
      if file.is_a? String  # a filename
        filename = file
        File.open(file) 
      else
        file
      end

    root = get_root_node_from_io(io)

    if filename
      io.close  # can close now
    end

    # right now we are only finding the first msRun (probably a rare case of
    # multiple runs in an mzXML file...)
    msrun_n = 
      if @version >= '2.0' 
        kids = root.children.select {|v| v.name == 'msRun' }
        raise(NotImplementedError, "one msrun per doc right now" ) if kids.size > 1
        kids.first
      else
        root
      end
    if msrun_n.name != 'msRun'
      raise RuntimeError, "extra node slipped in somehow"
    end

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
    lazy = opts[:lazy]

    if @version >= '3.0'
      warn '[version 3.0 parsing may fail if > 1 peak list per scan]'
      # note that mzXML version 3.0 *can* have more than one peak...
      # I'm not sure how to deal with that since I have one spectrum/scan
    end

    scan_nodes = msrun_n.find('child::scan')
    add_scan_nodes(scan_nodes, scans, scn_index, scans_by_num, lazy, io)

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


