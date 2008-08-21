require 'rexml/document'
require 'rexml/streamlistener'

module MS::Parser::MzXML::REXMLStreamListener; end
class MS::Parser::MzXML::REXMLStreamListener::PrecMzByNum; end

module REXMLStreamListenerHelper
  def parse_and_report(file, const, report_method=:report)
    listener = self.const_get(const).new
    File.open(file) do |fh|
      REXML::Document.parse_stream(fh, listener)
    end
    listener.send(report_method)
  end
end

class MS::Parser::MzXML::REXML 
  include MS::Parser::MzXML

  def initialize(version='1.0', method=:msrun)
    @version = version
    @method = parse_type
  end

  # returns an array indexed by scan_num that gives the precursor_mz
  def precursor_mz_by_scan(file, opts={})
    parse_and_report(file, PrecMzByNum)
  end

end




# for REXML
class MS::Parser::MzXML::REXML::PrecMzByNum
  include REXML::StreamListener

  attr_accessor :prec_mz
  alias_method :report, :prec_mz

  def initialize
    @prec_mz = [] 
    @scan_num = nil
    @get_data = false
  end

  def tag_start(name,attrs)
    if name == "scan"
      @scan_num = attrs["num"].to_i 
    elsif name == "precursorMz"
      @get_data = true
    end
  end

  def tag_end(name)
    if name == "precursorMz"
      @get_data = false
    end
  end

  def text(txt)
    if @get_data
      @prec_mz[@scan_num] = txt
    end
  end

end




