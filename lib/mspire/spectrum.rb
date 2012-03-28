require 'mspire/spectrum_like'

module Mspire
  class Spectrum
    include Mspire::SpectrumLike

    def self.from_peaklist(peaklist)
      _mzs = []
      _ints = []
      peaklist.each do |mz, int|
        _mzs << mz
        _ints << int
      end
      self.new([_mzs, _ints])
    end

  end
end




