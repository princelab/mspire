require 'mspire/mzml/list'
require 'mspire/cv/paramable'

module Mspire
  class Mzml
    # MUST supply a *child* term of MS:1000455 (ion selection attribute) one or more times
    #
    #     e.g.: MS:1000041 (charge state)
    #     e.g.: MS:1000042 (intensity)
    #     e.g.: MS:1000633 (possible charge state)
    #     e.g.: MS:1000744 (selected ion m/z)
    class SelectedIon
      include Mspire::CV::Paramable
      extend Mspire::Mzml::List
    end
  end
end
