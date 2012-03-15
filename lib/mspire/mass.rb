require 'mspire/isotope'
require 'mspire/molecular_formula'

module Mspire
  module Mass

    # takes a molecular formula in this format: C2BrH12O
    def self.formula_to_exact_mass(formula)
      Mspire::MolecularFormula.new(formula).map do |el,cnt|
        MONO[el] * cnt
      end.reduce(:+)
    end

    MONO_STR = {
      'h+' => 1.00727646677,
      'e' => 0.0005486,   # www.mikeblaber.org/oldwine/chm1045/notes/Atoms/.../Atoms03.htm
      'neutron' => 1.0086649156,
    }
    Mspire::Isotope::BY_ELEMENT.each do |el, isotopes|
      MONO_STR[el.to_s] = isotopes.find {|iso| iso.mono }.atomic_mass
    end
    MONO_STR['h2o'] = %w(h h o).map {|el| MONO_STR[el] }.reduce(:+)
    MONO_STR['oh'] = %w(o h).map {|el| MONO_STR[el] }.reduce(:+)
    # add on deuterium
    MONO_STR['d'] = Mspire::Isotope::BY_ELEMENT[:h].find {|iso| iso.element == :h && iso.mass_number == 2 }.atomic_mass

    AVG_STR = {
      'h+' => 1.007276, # using Mascot_H_plus mass (is this right for AVG??)
      'e' => 0.0005486,
      'neutron' => 1.0086649156,
    }
    Mspire::Isotope::BY_ELEMENT.each do |el, isotopes|
      AVG_STR[el.to_s] = isotopes.first.average_mass
    end
    AVG_STR['h2o'] = %w(h h o).map {|el| AVG_STR[el] }.reduce(:+)
    AVG_STR['oh'] = %w(o h).map {|el| AVG_STR[el] }.reduce(:+)

    # sets MONO_SYM, MONO, AVG_SYM, and AVG
    %w(MONO AVG).each do |type|
      const_set "#{type}_SYM", Hash[ const_get("#{type}_STR").map {|k,v| [k.to_sym, v] } ]
      const_set type, const_get("#{type}_STR").merge( const_get("#{type}_SYM") )
    end

    ELECTRON = MONO[:e]
    NEUTRON = MONO[:neutron]
    H_PLUS = MONO['h+']

  end
end


