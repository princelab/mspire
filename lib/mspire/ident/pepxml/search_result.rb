require 'nokogiri'

require 'mspire/ident/pepxml/search_hit'

module Mspire ; end
module Mspire::Ident ; end
class Mspire::Ident::Pepxml ; end

class Mspire::Ident::Pepxml::SearchResult
  # an array of search_hits
  attr_accessor :search_hits

  # if block given, then yields an empty search_hits array.
  # For consistency with other objects, will also take a hash that has the key
  # :search_hits and the value an array.
  def initialize(search_hits = [], &block)
    @search_hits = search_hits
    if search_hits.is_a?(Hash)
      @search_hits = search_hits[:search_hits]
    end
    block.call(@search_hits) if block
  end

  def to_xml(builder=nil)
    xmlb = builder || Nokogiri::XML::Builder.new
    builder.search_result do |xmlb|
      search_hits.each do |sh|
        sh.to_xml(xmlb)
      end
    end
    builder || xmlb.doc.root.to_xml 
  end

end

