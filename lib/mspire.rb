
require 'mspire/mass/aa' # requires mspire/mass & therefore mspire/molecular_formula

module Mspire
  VERSION = IO.read(File.join(File.dirname(__FILE__), '..', 'VERSION')).chomp
  CITE = "Prince JT, Marcotte EM. mspire: mass spectrometry proteomics in Ruby. Bioinformatics. 2008. 24(23):2796-7."
end
