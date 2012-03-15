require 'mspire/isotope'
require 'mspire/isotope/aa'
require 'mspire/mass'

module Mspire
  class MolecularFormula < Hash

    # integer desribing the charge state
    # mass calculations will add/remove electron mass from this
    attr_accessor :charge
    # takes a string or a hash:
    #
    #     "H22C12N1O3S2BeLi2"                    # <= order doesn't matter
    #     {h: 22, c: 12, n: 1, o: 3, s: 2}  # case and string/sym doesn't matter
    def initialize(arg, charge=0)
      @charge = charge
      if arg.is_a?(String)
        arg.scan(/([A-Z][a-z]?)(\d*)/).each do |k,v| 
          self[k.downcase.to_sym] = (v == '' ? 1 : v.to_i)
        end
      else
        self.merge!(arg)
      end
    end

    def self.from_aaseq(aaseq)
      hash = aaseq.each_char.inject({}) do |hash,aa| 
        hash.merge(Mspire::Isotope::AA::ATOM_COUNTS[aa]) {|h,o,n| (o ? o : 0) +n }
      end
      hash[:h] += 2
      hash[:o] += 1
      self.new(hash)
    end

    # gives the monoisotopic mass adjusted by the current charge
    def mass
      mss = inject(0.0) {|sum,(el,cnt)| sum + (Mspire::Mass::MONO[el]*cnt) }
      mss - (Mspire::Mass::ELECTRON * charge)
    end

  end
end
