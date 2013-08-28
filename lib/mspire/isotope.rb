require 'yaml'

module Mspire
  class Isotope
    MEMBERS = [
      :atomic_number, 
      :element, 
      :mass_number, 
      :atomic_mass, 
      :relative_abundance, 
      :average_mass, 
      :mono
    ].each {|key| attr_accessor key }

    def initialize(*args)
      MEMBERS.zip(args) {|k,val| self.send("#{k}=", val) }
    end
  end
end

require 'mspire/isotope/neese'
# sets Mspire::Isotope::BY_ELEMENTS and Mspire::Isotope::ISOTOPES

module Mspire
  class Isotope
    BY_ELEMENT = Mspire::Isotope::Neese::BY_ELEMENT
    ISOTOPES = Mspire::Isotope::Neese::ISOTOPES
  end
end


