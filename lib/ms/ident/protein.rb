require 'andand'

module MS ; end
module MS::Ident
  module ProteinLike
    # an id for the protein
    attr_accessor :id

    # the protein sequence
    attr_accessor :sequence
    alias_method :seq, :sequence
    alias_method :seq=, :sequence=

    # a description of the protein
    attr_accessor :description

    # if the GN=([^\s]+) regexp is found in the description, returns the first
    # match, or nil if not found
    def gene_id
      description.andand[/ GN=(\w+) ?/, 1]
    end
  end

  # a generic protein class that is ProteinLike
  class Protein
    include ProteinLike

    def initialize(id=nil, sequence=nil)
      (@id, @sequence) = id, sequence
    end
  end
end

