require 'merge'

require 'mspire/ident/pepxml/msms_run_summary'

module Mspire ; end
module Mspire::Ident ; end
class Mspire::Ident::Pepxml; end

class Mspire::Ident::Pepxml::MsmsPipelineAnalysis
  include Merge
  XMLNS = "http://regis-web.systemsbiology.net/pepXML"
  XMLNS_XSI = "http://www.w3.org/2001/XMLSchema-instance"
  # (this doesn't actually exist), also, the space is supposed to be there
  XSI_SCHEMA_LOCATION_BASE = "http://regis-web.systemsbiology.net/pepXML /tools/bin/TPP/tpp/schema/pepXML_v"
  # the only additions concerning a writer are from v18 are to the 'spectrum': retention_time_sec and activationMethodType
  PEPXML_VERSION = 115

  #include SpecIDXML
  # Version 1.2.3
  #attr_writer :date
  #attr_writer :xmlns, :xmlns_xsi, :xsi_schemaLocation
  #attr_accessor :summary_xml 
  
  attr_accessor :xmlns
  attr_accessor :xmlns_xsi
  attr_accessor :xsi_schema_location
  # an Integer
  attr_accessor :pepxml_version
  # self referential path to the outputfile
  attr_accessor :summary_xml
  attr_accessor :msms_run_summary
  attr_writer :date

  def block_arg 
    @msms_run_summary = Mspire::Ident::Pepxml::MsmsRunSummary.new
  end

  # if block given, yields a new msms_run_summary to return value of block
  def initialize(hash={}, &block)
    @xmlns = XMLNS
    @xmlns_xsi = XMLNS_XSI
    @xsi_schema_location = xsi_schema_location
    @pepxml_version = PEPXML_VERSION
    merge!(hash, &block)
  end

  # returns the location based on the pepxml version number
  def xsi_schema_location
    XSI_SCHEMA_LOCATION_BASE + pepxml_version.to_s + '.xsd'
  end

  # if no date string given, then it will set to Time.now
  def date
    return @date if @date
    tarr = Time.now.to_a 
    tarr[3..5].reverse.join('-') + "T#{tarr[0..2].reverse.join(':')}"
  end

  # uses the filename as summary_xml (if it is nil) attribute and builds a complete, valid xml document,
  # writing it to the filename
  def to_xml(builder)
    xmlb = builder || Nokogiri::XML::Builder.new
    xmlb.msms_pipeline_analysis(:date => date, :xmlns => xmlns, 'xsi:schemaLocation'.to_sym => xsi_schema_location, :summary_xml => summary_xml) do |xmlb|
      msms_run_summary.to_xml(xmlb) if msms_run_summary
    end
    builder || xmlb.doc.root.to_xml
  end
end


