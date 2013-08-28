require 'mspire/isotope'

class Mspire::Isotope::NIST::Updater
  NIST_ISOTOPE_SITE = 'http://physics.nist.gov/cgi-bin/Compositions/stand_alone.pl?ele=&all=all&ascii=ascii2&isotype=some'

  class << self

    # Creates an isotope from a nist entry.  Sets mono to false, which is not
    # always correct (but needs to be corrected with additional info)
    def isotope_from_nist_line(*args)
      # atomic_number and mass_number are ints
      [0,2].each {|i| args[i] = args[i].to_i }
      # element is a downcase sym
      args[1] = args[1].to_sym
      # atomic_mass, relative_abundance, and average_mass as floats
      [3, 4, 5].each {|i| args[i] = args[i][/([\w.]*)/].to_f }
      # by default call every isotope the non-monoisotopic peak
      # (will correct it as a group)
      args << false
      Mspire::Isotope.new(*args)
    end

    def write_nist_info(filename)
      isotopes = isotopes_from_nist_site
      File.write(filename, isotopes.map {|isotope| Mspire::Isotope::MEMBERS.map {|key| isotope.send(key) }}.to_yaml)
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
        rel.size > 0 ? isotope_from_nist_line(*arr, rel, avg) : nil
      end.compact!

      # deuterium should be grouped with hydrogen, not as its own element!
      isotopes.find {|iso| iso.element == :D }.element = :H if deuterium_is_kind_of_hydrogen

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

if __FILE__ == $0
  require 'mspire/isotope/nist'
  Mspire::Isotope::NIST::Updater.write_nist_info(Mspire::Isotope::NIST::INFO_FILE_FULL_PATH)
end
