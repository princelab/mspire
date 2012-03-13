require 'ms/isotope'

module MS
  class MolecularFormula < Hash

    # takes a string or a hash:
    #
    #     "H22C12N1O3S2BeLi2"                    # <= order doesn't matter
    #     {h: 22, c: 12, n: 1, o: 3, s: 2}  # case and string/sym doesn't matter
    def initialize(arg)
      if arg.is_a?(String)
        arg.scan(/([A-Z][a-z]?)(\d*)/).each do |k,v| 
          self[k.downcase.to_sym] = (v == '' ? 1 : v.to_i)
        end
      else
        self.merge!(arg)
      end
    end

  end
end
