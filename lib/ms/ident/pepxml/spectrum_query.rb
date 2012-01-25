require 'nokogiri'
require 'ms/mass'
require 'merge'

require 'ms/ident/pepxml/search_result'

module MS ; end
module MS::Ident ; end
class MS::Ident::Pepxml ; end

# search_specification is a search constraint applied specifically to this query (a String)
class MS::Ident::Pepxml::SpectrumQuery
  include Merge
  DEFAULT_MEMBERS = [:spectrum, :start_scan, :end_scan, :precursor_neutral_mass, :index, :assumed_charge, :retention_time_sec, :search_specification, :search_results, :pepxml_version]
  
  class << self
    attr_writer :members
    def members
      @members || DEFAULT_MEMBERS
    end
  end

  members.each {|memb| attr_accessor memb }

  Required = Set.new([:spectrum, :start_scan, :end_scan, :precursor_neutral_mass, :index, :assumed_charge])
  Optional = [:retention_time_sec, :search_specification]
  
  # takes either a hash or an ordered list of values to set
  # yeilds an empty search_results array if given a block
  def initialize(*args, &block)
    @search_results = [] 
    if args.first.is_a?(Hash)
      merge!(args.first)
    else
      self.class.members.zip(args) do |k,v|
        send("#{k}=", v)
      end
    end
    block.call(@search_results) if block
  end

  def members
    self.class.members
  end

  ############################################################
  # FOR PEPXML:
  ############################################################
  def to_xml(builder=nil)
    xmlb = builder || Nokogiri::XML::Builder.new
    # all through search_specification
    attrs = members[0, 8].map {|at| v=send(at) ; [at, v] if v }
    attrs_hash = Hash[attrs]
    case pepxml_version
    when 18
      attrs_hash.delete(:retention_time_sec)
    end
    xmlb.spectrum_query(attrs_hash) do |xmlb|
      search_results.each do |search_result|
        search_result.to_xml(xmlb) 
      end
    end
    builder || xmlb.doc.root.to_xml
  end

  def self.from_pepxml_node(node)
    self.new.from_pepxml_node(node)
  end

  def from_pepxml_node(node)
    @spectrum = node['spectrum']
    @start_scan = node['start_scan'].to_i
    @end_scan = node['end_scan'].to_i
    @precursor_neutral_mass = node['precursor_neutral_mass'].to_f
    @index = node['index'].to_i
    @assumed_charge = node['assumed_charge'].to_i
    self
  end

  def self.calc_precursor_neutral_mass(m_plus_h, deltamass, h_plus=MS::Mass::H_PLUS)
    m_plus_h - h_plus + deltamass
  end
end


