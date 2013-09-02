require 'mspire/paramable'

module Mspire
  class Mzml
    # Typical params might be like:
    #
    #     accession="MS:1000501" name="scan window lower limit" value="400"
    #     accession="MS:1000500" name="scan window upper limit" value="1800"
    class ScanWindow
      include Mspire::Paramable
      extend Mspire::Mzml::List

      def to_xml(builder)
        builder.scanWindow do |xml|
          super(xml)
        end
      end
    end
  end
end
