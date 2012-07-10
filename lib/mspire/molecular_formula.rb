require 'mspire/isotope'
require 'mspire/mass'

module Mspire
  class MolecularFormula < Hash

    class << self
      def from_aaseq(aaseq)
        hash = aaseq.each_char.inject({}) do |hash,aa| 
          hash.merge(Mspire::Isotope::AA::FORMULAS[aa]) {|h,o,n| (o ? o : 0) +n }
        end
        hash[:h] += 2
        hash[:o] += 1
        self.new(hash)
      end

      # takes a string, properly capitalized with the formula.  The elements
      # may be in any order.
      #
      #     "H22C12N1O3S2BeLi2"                    # <= order doesn't matter
      def from_string(mol_form_str, charge=0)
        mf = self.new({}, charge)
        mol_form_str.scan(/([A-Z][a-z]?)(\d*)/).each do |k,v| 
          mf[k.downcase.to_sym] = (v == '' ? 1 : v.to_i)
        end
        mf
      end

      alias_method :[], :from_string
    end

    # integer desribing the charge state
    # mass calculations will add/remove electron mass from this
    attr_accessor :charge

    # Takes a hash and an optional Integer expressing the charge
    #     {h: 22, c: 12, n: 1, o: 3, s: 2}  # case and string/sym doesn't matter
    def initialize(hash={}, charge=0)
      @charge = charge
      self.merge!(hash)
    end

    # returns a new formula object where all the atoms have been added up
    def +(*others)
      self.dup.add!(*others)
    end

    # returns self
    def add!(*others)
      others.each do |other|
        self.merge!(other) {|key, oldval, newval| self[key] = oldval + newval }
        self.charge += other.charge
      end
      self
    end

    # returns a new formula object where all the formulas have been subtracted
    # from the caller
    def -(*others)
      self.dup.sub!(*others)
    end

    def sub!(*others)
      others.each do |other|
        oth = other.dup
        self.each do |k,v|
          if oth.key?(k)
            self[k] -= oth.delete(k)
          end
        end
        oth.each do |k,v|
          self[k] = -v
        end
        self.charge -= other.charge
      end
      self
    end

    def *(int)
      self.dup.mul!(int)
    end

    def mul!(int, also_do_charge=true)
      raise ArgumentError, "must be an integer" unless int.is_a?(Integer)
      self.each do |k,v|
        self[k] = v * int
      end
      self.charge *= int if also_do_charge
      self
    end

    def /(int)
      self.dup.div!(int)
    end

    def div!(int, also_do_charge=true)
      raise ArgumentError, "must be an integer" unless int.is_a?(Integer)
      self.each do |k,v|
        quotient, modulus = v.divmod(int)
        raise ArgumentError "all numbers must be divisible by int" unless modulus == 0
        self[k] = quotient
      end
      if also_do_charge
        quotient, modulus = self.charge.divmod(int) 
        raise ArgumentError "charge must be divisible by int" unless modulus == 0
        self.charge = quotient
      end
      self
    end

    # gives the monoisotopic mass adjusted by the current charge (i.e.,
    # adds/subtracts electron masses for the charges)
    def mass(consider_electron_masses = true)
      mss = inject(0.0) {|sum,(el,cnt)| sum + (Mspire::Mass::MONO[el]*cnt) }
      mss -= (Mspire::Mass::ELECTRON * charge) if consider_electron_mass
      mss
    end

    # returns nil if the charge == 0
    def mz(consider_electron_masses = true)
      if charge == 0
        nil
      else
        mass(consider_electron_masses) / charge
      end
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
