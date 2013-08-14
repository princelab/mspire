require 'mspire/isotope'
require 'mspire/mass/util'

module Mspire
  module Mass
    module Element

      AVG_STRING = {}
      MONO_STRING = {}
      Mspire::Isotope::BY_ELEMENT.each do |el, isotopes|
        AVG_STRING[el.to_s] = isotopes.first.average_mass
        MONO_STRING[el.to_s] = isotopes.find {|iso| iso.mono }.atomic_mass
      end

      MONO_STRING['D'] = Mspire::Isotope::BY_ELEMENT[:H].find {|iso| iso.element == :H && iso.mass_number == 2 }.atomic_mass

      MONO_SYMBOL = Mspire::Mass::Util.symbol_keys( MONO_STRING )
      AVG_SYMBOL = Mspire::Mass::Util.symbol_keys( AVG_STRING )
      MONO = MONO_SYMBOL.merge(MONO_STRING)
      AVG = AVG_SYMBOL.merge(AVG_STRING)

      class << self
        def [](key)
          MONO[key]
        end
      end

    end
  end
end
