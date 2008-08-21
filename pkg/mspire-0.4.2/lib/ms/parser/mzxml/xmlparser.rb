require 'xmlparser_wrapper'

# this is the wrapper class
class MS::Parser::MzXML::XMLParser
  include XMLStyleParser
  include MS::Parser::MzXML
  include XMLParserWrapper

  def initialize(parse_type=:msrun, version='1.0')
    @method = parse_type
    @version = version
  end

  # returns: [times_arr, [m/z,inten,m/z,inten...]]
  # where times are time strings (in seconds)
  def times_and_spectra(file, opts={})
    parse_and_report(file, 'TimesAndSpectra')
  end


  ## IN PROGRESS ...
  # opts is actually the msrun object that will be fleshed out in the parsing
  def msrun(file, opts={})
    p opts
    fh = File.open(file)
    reply = parse_and_report_io(fh, 'MsRunHeader')
    p reply
    abort
    fh.close
  end

  def prec_mz_by_scan_num(file, opts={})
  end

  # could easily do this for all these guys
  #def method_missing(*args)
  #  method = args.shift
  #  parse_and_report(
  #end

end

class MS::Parser::MzXML::XMLParser::MsRunHeader < XMLParser
  def initialize(version='1.0')
    @version = version
    @atts = []
  end

  def startElement(name,attrs)
    case name
    when 'msRun'
      @atts = attrs.values_at(%w(scanCount startTime endTime))
    end
  end

  def endElement(name)
    if name == 'dataProcessing'
      done
      reset
    end
  end
end

class MS::Parser::MzXML::XMLParser::Spectrum < XMLParser
  @@scan_atts = %w(num msLevel retentionTime startMz endMz)
  @@precursor_mz_atts = %w(precursorIntensity)


  def initialize(version='1.0')
    @version = version
    @spectrum = []
    @current_scan = nil
  end

  def report
    @spectrum
  end

  def startElement(name,attrs)
    if name == 'scan'
      vals = attrs.values_at(@@scan_atts)
      vals[2] = vals[2][2...-1].to_f  #remove PT and trailing S
      [0, 1].each do |i| vals[i] = vals[i].to_i end # num and ms_level
      [3, 4].each do |i| vals[i] = vals[i].to_f end # start_mz and end_mz
      @current_scan = MS::Scan.new(vals)
    elsif name == 'precursorMz'
      # 5, 6, 7 are the scans indices for prec_mz prec_inten and parent
      @current_scan[6] = attrs['precursorIntensity'].to_f
      @current_scan[5] = ''
      @get_precursor_mz = true
    elsif name == 'peaks'
      @precision = attrs['precision'].to_i
      @get_peaks = true
      @current_peaks_string = ''
    end
  end

  def endElement(name)
    if name == 'peaks'
      @get_peaks = false
      @spectrum << Spectrum.new(@current_peaks_string, @precision)
      @spectrum.context = @current_scan
    elsif name == 'precursorMz'
      @current_scan[5] = @current_scan[5].to_f
      @get_precursor_mz = false
    end
  end

  def character(data)
    if @get_peaks
      @current_peaks_string << data 
    elsif @get_precursor_mz
      @current_scan[5] << data
    end
  end

end




class MS::Parser::MzXML::XMLParser::PrecMzByNum < XMLParser
  @scan_num = nil
  @get_data = false

  attr_accessor :prec_mz
  alias_method :report, :prec_mz

  def initialize
    @prec_mz = [] 
  end

  def startElement(name,attrs)
    if name == "scan"
      @scan_num = attrs["num"].to_i
    elsif name == "precursorMz"
      @current_prec_mz = ""
      @get_data = true
    end
  end

  def endElement(name)
    if name == "precursorMz"
      @get_data = false
      @prec_mz[@scan_num] = @current_prec_mz.to_f
    end
  end

  def character(data)
    if @get_data
      @current_prec_mz << data
    end
  end

end


=begin


# Returns parallel arrays (times, spectra) where each spectra is an array
# containing alternating mz and intensity (MS1 scans only)
# and times are strings with the time in seconds
class MS::Parser::MzXML::XMLParser::TimesAndSpectra < XMLParser
  include MS::Parser::MzXML
  @@get_data = false
  @@get_peaks = false
  @@precision = 32 # @TODO: set dynamic

  attr_accessor :times, :spectra
  def times_and_spectra
    [@times, @spectra]
  end

  alias_method :report, :times_and_spectra

  def initialize(ms_level=1)
    @ms_level = "#{ms_level}"
    @times = []
    @spectra = []
  end

  def startElement(name,attrs)
    if name == "scan" && attrs["msLevel"] == @ms_level
      @times << attrs["retentionTime"][2...-1]  # strip PT and S: "PTx.xxxxS"
      @@get_peaks = true
    elsif name == "peaks" && @@get_peaks
      @@get_data = true
      @data = ""
    end
  end

  def character(data)
    if @@get_data
      @data << data
    end
  end

  def endElement(name)
    if name == "peaks" && @@get_peaks
      @spectra << base64_peaks_to_array(@data, @@precision)
      @@get_data = false
      @@get_peaks = false
    end
  end

end


class MS::Parser::MzXML::XMLParser::TimeMzIntenIndexer < XMLParser

  @@scan_num = nil
  @@get_data = false

  attr_accessor :scans_by_num
  alias_method :report, :scans_by_num

  def initialize
    @current_scan = nil
    @scans_by_num = []
  end

  def startElement(name,attrs)
    if name == "scan"
      num = attrs["num"].to_i
      @current_scan = MS::Scan.new(num, attrs["msLevel"].to_i, attrs["retentionTime"].gsub(/^PT/,'').gsub(/S$/,'').to_f)
      scans_by_num[num] = @current_scan
    elsif name == "precursorMz"
      @current_scan.prec_inten = attrs["precursorIntensity"].to_f
      @@get_data = true
    end
  end

  def endElement(name)
    if name == "precursorMz"
      @@get_data = false
    end
  end

  def character(data)
    if @@get_data
      @current_scan.prec_mz = data
    end
  end

end

=end
