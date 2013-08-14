require 'mspire/mass/util'

module Mspire
  module Mass
    # provides hashes with both Amino Acids (uppercase letters) and elements
    # (lowercased) along with common abbreviations
    module All
      def self.downcase_keys(hash)
        Hash[ hash.map {|key,val| [key.to_s.downcase, val] } ]
      end

      MONO_STRING = downcase_keys( Element::MONO_STRING )
        .merge( downcase_keys( Common::MONO_STRING ) )
        .merge( AA::MONO_STRING )
        .merge( downcase_keys( Subatomic::MONO_STRING ) )

      MONO_SYMBOL = Mspire::Mass::Util.symbol_keys( MONO_STRING )
      MONO = MONO_STRING.merge( MONO_SYMBOL )

      AVG_STRING = downcase_keys( Element::AVG_STRING )
        .merge( downcase_keys( Common::AVG_STRING ) )
        .merge( AA::AVG_STRING )
        .merge( downcase_keys( Subatomic::MONO_STRING ) )  
        # ^^ NOTE: we use MONO values for Subatomic since avg makes no sense

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
