require 'mspire/cv/paramable'

module Mspire
  module Identml

    # a parameter for a spectral search.  An idealized modification.  See
    # Modification for describing a modification on an actual peptide.
    class SearchModification
      include Mspire::CV::Paramable

      # boolean
      attr_accessor :fixed_mod

      # mass delta in daltons
      attr_accessor :mass_delta

      # A *Set* of characters. From mzIdentml: "The residue(s) searched with the
      # specified modification. For N or C terminal modifications that can occur
      # on any residue, the . character should be used to specify any, otherwise
      # the list of amino acids should be provided."
      attr_accessor :residues

      # A single SpecificityRules object
      attr_accessor :specificity_rules

    end

  end
end
