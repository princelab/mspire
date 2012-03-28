
module Mspire
  # A peak is typically a doublet: an x value and a y value.  In a spectrum
  # this will be an m/z and intensity.  In a chromatogram this will be a
  # retention time and an intensity.  (This class can be subclassed if
  # desired)
  class Peak < Array
    alias_method :x, :first
    alias_method :y, :last
  end
end
