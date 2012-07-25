require 'mspire/cv/paramable'

module Mspire
  class Mzml
    # Typical params might be like:
    #
    #     accession="MS:1000501" name="scan window lower limit" value="400"
    #     accession="MS:1000500" name="scan window upper limit" value="1800"
    class ScanWindow
      include Mspire::CV::Paramable
      extend Mspire::Mzml::List
    end
  end
end
