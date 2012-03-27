require 'mspire/cv/paramable'

module Mspire
  class Mzml
    # Typical params might be like:
    #
    #     accession="MS:1000501" name="scan window lower limit" value="400"
    #     accession="MS:1000500" name="scan window upper limit" value="1800"
    class ScanWindow
      include Mspire::CV::Paramable

      def self.from_xml(xml)
        obj = self.new
        [:cvParam, :userParam].each {|v| obj.describe! xml.xpath("./#{v}") }
        obj
      end
    end
  end
end
