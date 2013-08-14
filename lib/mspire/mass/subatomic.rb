require 'mspire/mass/util'
require 'mspire/mass/element'

module Mspire
  module Mass
    module Subatomic
      MONO_STRING = {
        'electron' => 0.0005486,   # www.mikeblaber.org/oldwine/chm1045/notes/Atoms/.../Atoms03.htm
        'neutron' => 1.0086649156,
      }
      MONO_STRING['proton'] = Mspire::Mass::Element[:H] - MONO_STRING['electron']
      MONO_STRING['H+'] = MONO_STRING['proton']
      MONO_STRING['e'] = MONO_STRING['electron']

      MONO_SYMBOL = Mspire::Mass::Util.symbol_keys( MONO_STRING )
      MONO = MONO_STRING.merge( MONO_SYMBOL )

      class << self
        def [](key)
          MONO[key]
        end
      end

      # 'h+' => 1.00727646677,
    end
  end
end
