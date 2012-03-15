require 'yaml'

module Mspire
  class Isotope
    MEMBERS = [:atomic_number, :element, :mass_number, :atomic_mass, :relative_abundance, :average_mass, :mono]
    MEMBERS.each {|key| attr_accessor key }

    INFO_FILE = 'nist_isotope_info.yml'
    INFO_FILE_FULL_PATH = File.expand_path(File.dirname(__FILE__) + "/isotope/#{INFO_FILE}")


    def initialize(*args)
      MEMBERS.zip(args) {|k,val| self.send("#{k}=", val) }
    end

    # Creates an isotope from a nist entry.  Sets mono to false, which is not
    # always correct (but needs to be corrected with additional info)
    def self.from_nist_line(*args)
      # atomic_number and mass_number are ints
      [0,2].each {|i| args[i] = args[i].to_i }
      # element is a downcase sym
      args[1] = args[1].downcase.to_sym
      # atomic_mass, relative_abundance, and average_mass as floats
      [3, 4, 5].each {|i| args[i] = args[i][/([\w.]*)/].to_f }
      # by default call every isotope the non-monoisotopic peak
      # (will correct it as a group)
      args << false
      self.new(*args)
    end

    if File.exist?(INFO_FILE_FULL_PATH)

      ISOTOPES = YAML.load_file(INFO_FILE_FULL_PATH).map {|ar| Mspire::Isotope.new *ar }
      BY_ELEMENT = ISOTOPES.group_by(&:element)

    else
      unless __FILE__ == $0
        warn "no file #{INFO_FILE_FULL_PATH} to read isotope information from"
        warn "directly running the file: #{__FILE__}"
        warn "will generate the file from NIST data"
      end
    end

    class Updater
      NIST_ISOTOPE_SITE = 'http://physics.nist.gov/cgi-bin/Compositions/stand_alone.pl?ele=&all=all&ascii=ascii2&isotype=some'
      class << self

        def write_nist_info(filename)
          isotopes = isotopes_from_nist_site
          File.write(filename, isotopes.map {|isotope| MEMBERS.map {|key| isotope.send(key) }}.to_yaml)
        end

        def isotopes_from_nist_site(deuterium_is_kind_of_hydrogen=true)
          require 'mechanize'
          body = Mechanize.new.get(NIST_ISOTOPE_SITE).body.split("\n")
          body.delete_if {|l| l[/^(<|\/)/]}
          body.shift(22)
          isotopes = body.each_slice(8).map do |lines|
            arr = (1..4).to_a.map {|i| match lines[i] }
            rel, avg = match(lines[5]), match(lines[6])
            next if rel.nil?
            rel.size > 0 ? Isotope.from_nist_line(*arr, rel, avg) : nil
          end.compact!

          # deuterium should be grouped with hydrogen, not as its own element!
          isotopes.find {|iso| iso.element == :d }.element = :h if deuterium_is_kind_of_hydrogen

          # update the mono boolean if this is the highest abundance peak
          isotopes.group_by(&:element).values.each do |set|
            set.max_by(&:relative_abundance).mono = true
          end
          isotopes
        end

        private

        def match(string)
          unless string.nil?
            if string.empty?
              nil
            else
              string[/= (.*)/,1]
            end
          end
        end 
      end 
    end 
  end
end

if __FILE__ == $0
  Mspire::Isotope::Updater.write_nist_info(Mspire::Isotope::INFO_FILE_FULL_PATH)
end
