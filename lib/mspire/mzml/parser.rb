require 'nokogiri'

module Mspire
  class Mzml
    module Parser
      NOBLANKS = ::Nokogiri::XML::ParseOptions::DEFAULT_XML | ::Nokogiri::XML::ParseOptions::NOBLANKS
    end
  end
end

