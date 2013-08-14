require 'mspire/mass/util'
require 'mspire/mass/element'

module Mspire
  module Mass
    module Common
      mono_string = Mspire::Mass::Element::MONO_STRING
      avg_string = Mspire::Mass::Element::AVG_STRING

      MONO_STRING = {
        'H2O' => %w(H H O).map {|el| mono_string[el] }.reduce(:+),
        'OH' => %w(O H).map {|el| mono_string[el] }.reduce(:+),
      }

      AVG_STRING = {
        'H2O' => %w(H H O).map {|el| avg_string[el] }.reduce(:+),
        'OH' => %w(O H).map {|el| avg_string[el] }.reduce(:+),
      }

      MONO_SYMBOL = Mspire::Mass::Util.symbol_keys( MONO_STRING )
      MONO = MONO_STRING.merge( MONO_SYMBOL )

      AVG_SYMBOL = Mspire::Mass::Util.symbol_keys( AVG_STRING )
      AVG = AVG_STRING.merge( AVG_SYMBOL )

      class << self
        def [](key)
          MONO[key]
        end
      end

    end
  end
end
