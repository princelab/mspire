require 'mspire/isotope'

module Mspire
  module Mass
    module Element

      AVG_STR = {}
      MONO_STR = {}
      Mspire::Isotope::BY_ELEMENT.each do |el, isotopes|
        AVG_STR[el.to_s] = isotopes.first.average_mass
        MONO_STR[el.to_s] = isotopes.find {|iso| iso.mono }.atomic_mass
      end

      MONO_STR['D'] = Mspire::Isotope::BY_ELEMENT[:H].find {|iso| iso.element == :H && iso.mass_number == 2 }.atomic_mass

      # sets MONO_SYM, MONO, AVG_SYM, and AVG
      %w(MONO AVG).each do |type|
        const_set "#{type}_SYM", Hash[ const_get("#{type}_STR").map {|k,v| [k.to_sym, v] } ]
        const_set type, const_get("#{type}_STR").merge( const_get("#{type}_SYM") )
      end

    end
  end
end
