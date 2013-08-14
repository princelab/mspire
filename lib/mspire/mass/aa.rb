require 'mspire/mass/util'

module Mspire
  module Mass
    module AA

      # amino_acids keys as strings, average masses
      AVG_STRING = {
        "*"=>118.88603,
        "A"=>71.0779,
        "B"=>172.1405,
        "C"=>103.1429,
        "D"=>115.0874,
        "E"=>129.11398,
        "F"=>147.17386,
        "G"=>57.05132,
        "H"=>137.13928,
        "I"=>113.15764,
        "K"=>128.17228,
        "L"=>113.15764,
        "M"=>131.19606,
        "N"=>114.10264,
        "O"=>211.28076,
        "P"=>97.11518,
        "Q"=>128.12922,
        "R"=>156.18568,
        "S"=>87.0773,
        "T"=>101.10388,
        "U"=>150.0379,
        "V"=>99.13106,
        "W"=>186.2099,
        "X"=>118.88603,
        "Y"=>163.17326,
        "Z"=>128.6231
      }

      # amino_acids keys as strings, monoisotopic masses
      MONO_STRING = {
        "*"=>118.805716,
        "A"=>71.0371137878,
        "B"=>172.048405,
        "C"=>103.0091844778,
        "D"=>115.026943032,
        "E"=>129.0425930962,
        "F"=>147.0684139162,
        "G"=>57.0214637236,
        "H"=>137.0589118624,
        "I"=>113.0840639804,
        "K"=>128.0949630177,
        "L"=>113.0840639804,
        "M"=>131.0404846062,
        "N"=>114.0429274472,
        "O"=>211.1446528645,
        "P"=>97.052763852,
        "Q"=>128.0585775114,
        "R"=>156.1011110281,
        "S"=>87.0320284099,
        "T"=>101.0476784741,
        "U"=>150.9536355878,
        "V"=>99.0684139162,
        "W"=>186.0793129535,
        "X"=>118.805716,
        "Y"=>163.0633285383,
        "Z"=>128.550585
      }

      # amino_acids keys as symbols, monoisotopic masses
      MONO_SYMBOL = Mspire::Mass::Util.symbol_keys( MONO_STRING )

      # amino_acids keys as symbols, average masses
      AVG_SYMBOL = Mspire::Mass::Util.symbol_keys( AVG_STRING )

      # Monoisotopic amino acid masses keyed as symbols and also strings 
      MONO = MONO_SYMBOL.merge(MONO_STRING)

      # Average amino acid masses keyed as symbols and also strings
      AVG = AVG_SYMBOL.merge(AVG_STRING)

      class << self
        def [](key) 
          MONO[key]
        end
      end
    end
  end
end
