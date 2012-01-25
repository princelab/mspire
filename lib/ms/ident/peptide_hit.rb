require 'merge'

module MS ; end
module MS::Ident ; end

module MS::Ident::PeptideHitLike
  attr_accessor :id
  attr_accessor :search
  attr_accessor :missed_cleavages
  attr_accessor :aaseq
  attr_accessor :charge
  # an array of MS::Ident::ProteinLike objects
  attr_accessor :proteins
  # relative to the set the hit is contained in!
  attr_accessor :qvalue
end

class MS::Ident::PeptideHit
  include MS::Ident::PeptideHitLike
  include Merge

  def initialize(hash)
    merge!(hash)
  end
end

