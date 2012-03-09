module MS
  module Isotope
    class << self
      def IsotopicAbundanceAndMassByElement
        @@isotopic_abundance_and_mass_by_element
      end
      def Isotopes
        @@isotopes
      end
      def IsotopesByElements
        @@isotopes_by_elements
      end
    end # class << self
    Isotope = Struct.new(:atomic_number, :element, :mass_number, :atomic_mass, :relative_abundance, :average_mass, :mono) do 
      def initialize(*args)
        super(*args, false)
        [:atomic_number, :mass_number].each {|n| self.send("#{n}=", self.send(n).to_i)}
        self.element= self.element.downcase.to_sym
        [:atomic_mass, :relative_abundance, :average_mass].each {|n| self.send("#{n}=", self.send(n)[/([\w.]*)/].to_f)}
      end
    end
    class Updater
      class << self
        def parse_NIST_site
          require 'mechanize'
          body = Mechanize.new.get('http://physics.nist.gov/cgi-bin/Compositions/stand_alone.pl?ele=&all=all&ascii=ascii2&isotype=some').body.split("\n")
          body.delete_if {|l| l[/^(<|\/)/]}
          body.shift(22)
          isotopes = body.each_slice(8).map do |lines|
            arr = (1..4).to_a.map {|i| match lines[i] }
            rel, avg = match(lines[5]), match(lines[6])
            next if rel.nil?
            rel.size > 0 ? Isotope.new(*arr, rel, avg) : nil
          end.compact!
          File.open("#{Time.now.to_i}_NIST_isotopes.txt", 'w')
        end #parse_NIST_site

        def group_by_element
          elements = @@isotopes.map(&:element)
          @@isotopes_by_elements = {}
          elements.each do |e|
            @@isotopes_by_elements[e] = []
          end
          @@isotopes.each do |iso|
            @@isotopes_by_elements[iso.element] << iso
          end
          @@isotopic_abundance_and_mass_by_element =  Hash[@@isotopes_by_elements.map {|k,val| [k, val.map {|v| [v.relative_abundance, v.atomic_mass, v.mass_number] }   ]}]  
        end #group_by_element
        private
        def match(string)
          unless string.nil?
            if string.empty?
              nil
            else
              string[/= (.*)/,1]
            end
          end
        end #match
      end # class << self
    end # Updater
  end #module Isotope
end # module MS

if __FILE__ == $0
  MS::Isotope::Updater.parse_NIST_site
  MS::Isotope::Updater.group_by_element
end
