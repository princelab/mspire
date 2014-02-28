
module Mspire
  module Mass
  end
end

require 'mspire/molecular_formula'
require 'mspire/mass/element'
require 'mspire/mass/subatomic'
require 'mspire/mass/common'
require 'mspire/mass/aa'

module Mspire
  module Mass

    ELECTRON = Subatomic::MONO[:e]
    NEUTRON = Subatomic::MONO[:neutron]
    PROTON = Subatomic::MONO[:proton]
    H_PLUS = PROTON

    class << self
      # takes a molecular formula as a string, hash or MolecularFormula object
      # and returns the exact mass.
      def formula_to_exact_mass(formula)
        Mspire::MolecularFormula.from_any(formula).mass
      end
      alias_method :formula, :formula_to_exact_mass

      def aa_to_exact_mass(aa_seq)
        chain_mass = aa_seq.each_char.inject(0.0) do |sum, aa_char|
          sum + AA[aa_char]
        end
        chain_mass + formula_to_exact_mass('H2O')
      end
      alias_method :aa, :aa_to_exact_mass

    end

  end
end


