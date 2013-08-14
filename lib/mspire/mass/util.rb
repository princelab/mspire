
module Mspire
  module Mass
    module Util
      def self.symbol_keys(hash)
        Hash[ hash.map {|key,val| [key.to_sym, val] } ]
      end
    end
  end
end
