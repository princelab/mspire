require 'merge'

module Mspire ; end
module Mspire::Ident ; end

module Mspire::Ident::PeptideHitLike
  attr_accessor :id
  attr_accessor :search
  attr_accessor :missed_cleavages
  attr_accessor :aaseq
  attr_accessor :charge
  # an array of Mspire::Ident::ProteinLike objects
  attr_accessor :proteins
  # relative to the set the hit is contained in!
  attr_accessor :qvalue
end

class Mspire::Ident::PeptideHit
  include Mspire::Ident::PeptideHitLike
  include Merge

  def initialize(hash=nil)
    merge!(hash) if hash
  end
end

