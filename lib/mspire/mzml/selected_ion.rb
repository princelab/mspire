require 'mspire/mzml/list'
require 'mspire/paramable'

module Mspire
  class Mzml
    # MUST supply a *child* term of MS:1000455 (ion selection attribute) one or more times
    #
    #     e.g.: MS:1000041 (charge state)
    #     e.g.: MS:1000042 (intensity)
    #     e.g.: MS:1000633 (possible charge state)
    #     e.g.: MS:1000744 (selected ion m/z)
    class SelectedIon
      include Mspire::Paramable
      extend Mspire::Mzml::List

      def to_xml(builder)
        builder.selectedIon {|xml| super(xml) }
      end
    end
  end
end
