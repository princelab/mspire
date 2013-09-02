require 'mspire/cv/paramable'

module Mspire
  module Mzid
    class Modification
      include Mspire::CV::Paramable
      # optional avg mass
      attr_accessor :avg_mass_delta

      # From IdentML spec: "Location of the modification within the peptide -
      # position in peptide sequence, counted from the N-terminus residue,
      # starting at position 1.  Specific modifications to the N-terminus
      # should be given the location 0. Modification to the C-terminus should
      # be given as peptide length + 1. If the modification location is
      # unknown e.g. for PMF data, this attribute should be omitted."
      attr_accessor :location

      attr_accessor :monoisotopic_mass_delta

      # Array of residues. Specification of the residue (amino acid) on which
      # the modification occurs. If multiple values are given, it is assumed
      # that the exact residue modified is unknown i.e. the modification is to
      # ONE of the residues listed. Multiple residues would usually only be
      # specified for PMF data.
      attr_accessor :residues

    end
  end
end
