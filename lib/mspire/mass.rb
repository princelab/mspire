require 'mspire/molecular_formula'
require 'mspire/mass/element'
require 'mspire/mass/aa'

module Mspire
  module Mass

    # takes a molecular formula as a string, hash or MolecularFormula object
    # and returns the exact mass.
    def self.formula_to_exact_mass(formula)
      Mspire::MolecularFormula.from_any(formula).mass
    end


    # sets MONO_SYM, MONO, AVG_SYM, and AVG
    %w(MONO AVG).each do |type|
      const_set "#{type}_SYM", Hash[ const_get("#{type}_STR").map {|k,v| [k.to_sym, v] } ]
      const_set type, const_get("#{type}_STR").merge( const_get("#{type}_SYM") )
    end

    ELECTRON = MONO[:e]
    NEUTRON = MONO[:neutron]
    H_PLUS = MONO['H+']

  end
end


