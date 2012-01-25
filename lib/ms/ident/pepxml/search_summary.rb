require 'ms/ident/pepxml/search_database'
require 'ms/ident/pepxml/modifications'
require 'ms/ident/pepxml/parameters'

require 'nokogiri'
require 'merge'

module MS ; end
module MS::Ident ; end
class MS::Ident::Pepxml ; end


# requires these keys:  
#
#    :enzyme => a valid enzyme name
#    :max_num_internal_cleavages => max number of internal cleavages allowed
#    :min_number_termini => minimum number of termini??
class MS::Ident::Pepxml::EnzymaticSearchConstraint < Hash
end

class MS::Ident::Pepxml::SearchSummary
  include Merge

  DEFAULT_SEARCH_ID = '1'

  attr_accessor :base_name
  # required in v18-19, optional in later versions
  attr_accessor :out_data_type
  # required in v18-19, optional in later versions
  attr_accessor :out_data
  # by default, "1"
  attr_accessor :search_id
  # an array of MS::Ident::Pepxml::Modification objects
  attr_accessor :modifications
  # A SearchDatabase object (responds to :local_path and :type)
  attr_accessor :search_database
  # the other search paramaters as a hash
  attr_accessor :parameters
  # the search engine used, SEQUEST, Mascot, Comet, etc.
  attr_accessor :search_engine
  # required: 'average' or 'monoisotopic'
  attr_accessor :precursor_mass_type
  # required: 'average' or 'monoisotopic'
  attr_accessor :fragment_mass_type
  # An EnzymaticSearchConstraint object (at the moment this is merely a hash
  # with a few required keys
  attr_accessor :enzymatic_search_constraint

  def block_arg
    [@search_database = MS::Ident::Pepxml::SearchDatabase.new,
      @enzymatic_search_constraint = MS::Ident::Pepxml::EnzymaticSearchConstraint.new,
      @modifications,
      @parameters = MS::Ident::Pepxml::Parameters.new,
    ]
  end

  # initializes modifications to an empty array
  def initialize(hash={}, &block)
    @modifications = []
    @search_id = DEFAULT_SEARCH_ID
    merge!(hash, &block)
  end

  def to_xml(builder=nil)
    # TODO: out_data and out_data_type are optional in later pepxml versions...
    # should work that in...
    attrs = [:base_name, :search_engine, :precursor_mass_type, :fragment_mass_type, :out_data_type, :out_data, :search_id]
    hash = Hash[ attrs.map {|at| v=send(at) ; [at, v] if v }.compact ]
    xmlb = builder || Nokogiri::XML::Builder.new
    builder.search_summary(hash) do |xmlb|
      search_database.to_xml(xmlb)
      xmlb.enzymatic_search_constraint(enzymatic_search_constraint) if enzymatic_search_constraint
      modifications.each do |mod|
        mod.to_xml(xmlb)
      end
      parameters.to_xml(xmlb) if parameters
    end
    builder || xmlb.doc.root.to_xml 
  end

  def self.from_pepxml_node(node)
    self.new.from_pepxml_node(node)
  end

  def from_pepxml_node(node)
    raise NotImplementedError, "not implemented just yet (just use the raw xml node)"
  end

end



