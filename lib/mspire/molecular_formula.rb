require 'mspire/isotope'
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

    # returns a new formula object where all the atoms have been added up
    def +(*others)
      new_form = self.dup
      others.each do |form|
        new_form.merge!(form) {|key, oldval, newval| new_form[key] = oldval+newval }
      end
      new_form
    end

    def self.from_aaseq(aaseq)
      hash = aaseq.each_char.inject({}) do |hash,aa| 
        hash.merge(Mspire::Isotope::AA::FORMULAS[aa]) {|h,o,n| (o ? o : 0) +n }
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

    def to_s(alphabetize=true)
      h = alphabetize ? self.sort : self
      h.flat_map {|k,v| 
        [k.capitalize, v > 1 ? v : '']
      }.join
    end

    def to_hash
      Hash[ self ]
    end

    alias_method :old_equal, '=='.to_sym

    def ==(other)
      old_equal(other) && self.charge == other.charge
    end

  end
end

require 'mspire/isotope/aa'
