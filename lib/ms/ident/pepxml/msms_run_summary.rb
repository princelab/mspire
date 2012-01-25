require 'merge'
require 'nokogiri'

require 'ms/ident/pepxml/sample_enzyme'
require 'ms/ident/pepxml/search_summary'
require 'ms/ident/pepxml/spectrum_query'

module MS ; end
module MS::Ident ; end
class MS::Ident::Pepxml; end

class MS::Ident::Pepxml::MsmsRunSummary
  include Merge
  # The name of the pep xml file without any extension
  attr_accessor :base_name
  # The name of the mass spec manufacturer 
  attr_accessor :ms_manufacturer
  attr_accessor :ms_model
  attr_accessor :ms_mass_analyzer
  attr_accessor :ms_detector
  attr_accessor :raw_data_type
  attr_accessor :raw_data
  attr_accessor :ms_ionization
  attr_accessor :pepxml_version

  # A SampleEnzyme object (responds to: name, cut, no_cut, sense)
  attr_accessor :sample_enzyme
  # A SearchSummary object
  attr_accessor :search_summary
  # An array of spectrum_queries
  attr_accessor :spectrum_queries

  def block_arg
    [@sample_enzyme = MS::Ident::Pepxml::SampleEnzyme.new,    
      @search_summary = MS::Ident::Pepxml::SearchSummary.new,
      @spectrum_queries ]
  end

  # takes a hash of name, value pairs
  # if block given, yields a SampleEnzyme object, a SearchSummary and an array
  # for SpectrumQueries
  def initialize(hash={}, &block)
    @spectrum_queries = []
    merge!(hash, &block)
    block.call(block_arg) if block
  end

  # optionally takes an xml builder object and returns the builder, or the xml
  # string if no builder was given
  # sets the index attribute of each spectrum query if it is not already set
  def to_xml(builder=nil)
    xmlb = builder || Nokogiri::XML::Builder.new
    hash = {:base_name => base_name, :msManufacturer => ms_manufacturer, :msModel => ms_model, :msIonization => ms_ionization, :msMassAnalyzer => ms_mass_analyzer, :msDetector => ms_detector, :raw_data_type => raw_data_type, :raw_data => raw_data}
    hash.each {|k,v| hash.delete(k) unless v }
    xmlb.msms_run_summary(hash) do |xmlb|
      sample_enzyme.to_xml(xmlb) if sample_enzyme
      search_summary.to_xml(xmlb) if search_summary
      spectrum_queries.each_with_index do |sq,i| 
        sq.index = i+1 unless sq.index
        sq.to_xml(xmlb)
      end
    end
    builder || xmlb.doc.root.to_xml
  end

  def self.from_pepxml_node(node)
    self.new.from_pepxml_node(node)
  end

  # peps correspond to search_results
  def from_pepxml_node(node)
    @base_name = node['base_name']
    @ms_manufacturer = node['msManufacturer']
    @ms_model = node['msModel']
    @ms_manufacturer = node['msIonization']
    @ms_mass_analyzer = node['msMassAnalyzer']
    @ms_detector = node['msDetector']
    @raw_data_type = node['raw_data_type']
    @raw_data = node['raw_data']
    self
  end
end
