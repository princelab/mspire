require 'mspire/cv/paramable'

module Mspire
  class Mzml
    class Contact

      COMMON_PARAMS = {
        name: 'MS:1000586',
        organization: 'MS:1000590',
        address: 'MS:1000587',
        email: 'MS:1000589'
      }

      include Mspire::CV::Paramable

      def to_xml(builder)
        builder.contact do |fc_n|
          super(fc_n)
        end
      end
    end
  end
end
