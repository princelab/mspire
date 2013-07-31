require 'merge'
require 'nokogiri'

module Mspire ; end
module Mspire::Ident ; end
class Mspire::Ident::Pepxml ; end

# Modified aminoacid, static or variable
# unless otherwise stated, all attributes can be anything
class Mspire::Ident::Pepxml::AminoacidModification
  include Merge
  # The amino acid (one letter code)
  attr_accessor :aminoacid
  # Mass difference with respect to unmodified aminoacid, as a Float
  attr_accessor :massdiff
  # Mass of modified aminoacid, Float
  attr_accessor :mass
  # Y if both modified and unmodified aminoacid could be present in the
  # dataset, N if only modified aminoacid can be present
  attr_accessor :variable
  # whether modification can reside only at protein terminus (specified 'n',
  # 'c', or 'nc')
  attr_accessor :peptide_terminus
  # Symbol used by search engine to designate this modification
  attr_accessor :symbol
  # 'Y' if each peptide must have only modified or unmodified aminoacid, 'N' if a
  # peptide may contain both modified and unmodified aminoacid
  attr_accessor :binary

  def initialize(hash={})
    merge!(hash)
  end

  # returns the builder or an xml string if no builder supplied
  def to_xml(builder=nil)
    xmlb = builder || Nokogiri::XML::Builder.new
    # note massdiff: must begin with either + (nonnegative) or - [e.g.
    # +1.05446 or -2.3342] consider Numeric#to_plus_minus_string in
    # Mspire::Ident::Pepxml
    attrs = [:aminoacid, :massdiff, :mass, :variable, :peptide_terminus, :symbol, :binary].map {|at| v=send(at) ; [at,v] if v }.compact
    hash = Hash[attrs]
    hash[:massdiff] = hash[:massdiff].to_plus_minus_string
    xmlb.aminoacid_modification(hash)
    builder || xmlb.doc.root.to_xml
  end
end

# Modified aminoacid, static or variable
class Mspire::Ident::Pepxml::TerminalModification
  include Merge
  # n for N-terminus, c for C-terminus
  attr_accessor :terminus
  # Mass difference with respect to unmodified terminus
  attr_accessor :massdiff
  # Mass of modified terminus
  attr_accessor :mass
  # Y if both modified and unmodified terminus could be present in the
  # dataset, N if only modified terminus can be present
  attr_accessor :variable
  # symbol used by search engine to designate this modification
  attr_accessor :symbol
  # whether modification can reside only at protein terminus (specified n or
  # c)
  attr_accessor :protein_terminus
  attr_accessor :description

  def initialize(hash={})
    hash.each {|k,v| send("#{k}=", v) }
  end

  # returns the builder or an xml string if no builder supplied
  def to_xml(builder=nil)
    xmlb = builder || Nokogiri::XML::Builder.new
    #short_element_xml_from_instance_vars("terminal_modification")
   attrs = [:terminus, :massdiff, :mass, :variable, :protein_terminus, :description].map {|at| v=send(at) ; [at,v] if v }.compact
   hash = Hash[attrs] 
    hash[:massdiff] = hash[:massdiff].to_plus_minus_string
    xmlb.terminal_modification(hash)
    builder || xmlb.doc.root.to_xml
  end
end


