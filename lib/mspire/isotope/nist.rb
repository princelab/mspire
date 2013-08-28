require 'mspire/isotope'

module Mspire::Isotope::NIST
  INFO_FILE = 'isotope_info.yml'
  INFO_FILE_FULL_PATH = File.expand_path(File.dirname(__FILE__) + "/nist/#{INFO_FILE}")

  if File.exist?(INFO_FILE_FULL_PATH)

    ISOTOPES = YAML.load_file(INFO_FILE_FULL_PATH).map {|ar| Mspire::Isotope.new *ar }
    BY_ELEMENT = ISOTOPES.group_by(&:element)

  else
    unless __FILE__ == $0
      warn "no file #{INFO_FILE_FULL_PATH} to read isotope information from!"
      warn "Note that directly running the file: lib/mspire/isotope/nist/updater.rb"
      warn "will autogenerate this file from NIST data"
    end
  end
end 
