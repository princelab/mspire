# mspire

[![Gem Version][GV img]][Gem Version]
[![Build Status][BS img]][Build Status]
[![Dependency Status][DS img]][Dependency Status]
[![Code Climate][CC img]][Code Climate]

Mspire is a full featured library for working with mass spectrometry data,
particularly proteomic, metabolomic and lipidomic data sets.  It aims to be
fast, robust, and beautiful.

## Cite

Prince JT, Marcotte EM. <b>mspire: mass spectrometry proteomics in Ruby.</b> *Bioinformatics.* 2008 Dec 1;24(23):2796-7. ([pubmed](http://www.ncbi.nlm.nih.gov/pubmed/18930952))

## Features

### mzml

* Reading *and* writing
* True random access to spectra or chromatograms
* Complete object model with implicit object link resolution (even with random access)
* Simplified creation of and full support for CV params and referenceable param groups

### imzml

Mspire is the *only* commandline converter from mzml into imzml (also see [imzMLConverter](http://www.cs.bham.ac.uk/~ibs/imzMLConverter/)) 

* handles both processed and continuous modes
* gracefully handles SIM data

### Other Feature Highlights

* isotope distribution prediction: uses fastest method known (FFT convolution)
* protein digestion: Support for 32 enzymes/variants by name
* pepxml: full object model and complete write support
* fasta files: complete programmatic access to description lines (via bio-ruby)
* peak lists: merging/summing and splitting algorithms
* obo: ontology hash access
* molecular formulas: can do arithmetic with formulas
* calculates q-values

## Examples

```ruby
mzml_file = "yourfile.mzML"
```

### mzml

See Mspire::Mzml, Mspire::CV::Paramable, Mspire::Mzml::Spectrum and other
objects associated with Mzml files.

#### reading

```ruby
require 'mspire/mzml'

Mspire::Mzml.open(mzml_file) do |mzml|

  # random access by index or id (even if file wasn't indexed)
  spectrum = mzml[0]
  spectrum = mzml["controllerType=0 controllerNumber=1 scan=2"]

  spectrum.mzs
  spectrum.intensities

  # first 5 peaks
  spectrum.peaks[0,5].each do |mz, intensity|
    puts "#{mz} #{intensity}"
  end

  # true if key exists and no value, the value if present, or false
  if spectrum.fetch_by_acc('MS:1000128')
    puts "this is a profile spectrum!"
  end

  if spectrum.ms_level == 2
    low_mz = spectrum.scan_list.first.scan_windows.first.fetch_by_acc("MS:1000501").to_i
    puts "begin scan at #{low_mz} m/z"
  end
end
```

#### normalize spectra and write new mzML

See Mspire::Mzml for complete example building all objects from scratch.

```ruby
require 'mspire/mzml'

Mspire::Mzml.open(mzml_file) do |mzml|

  # MS:1000584 -> an mzML file
  mzml.file_description.source_files << Mspire::Mzml::SourceFile[mzml_file].describe!('MS:1000584')
  mspire = Mspire::Mzml::Software.new
  mzml.software_list.push(mspire).uniq_by(&:id)
  normalize_processing = Mspire::Mzml::DataProcessing.new("ms1_normalization") do |dp|
    # 'MS:1001484' -> intensity normalization 
    dp.processing_methods << Mspire::Mzml::ProcessingMethod.new(mspire).describe!('MS:1001484')
  end

  mzml.data_processing_list << normalize_processing

  spectra = mzml.map do |spectrum|
    normalizer = 100.0 / spectrum.intensities.max
    spectrum.intensities.map! {|i| i * normalizer }
    spectrum
  end
  mzml.run.spectrum_list = Mspire::Mzml::SpectrumList.new(normalize_processing, spectra)
  mzml.write(outfile)
end
```
### Masses

```ruby
# very high precision NIST masses
aa_to_mass = Mspire::Mass::AA::MONO # a hash with residue masses
aa_to_mass['A'] # or access by symbol - Alanine

# elements
Mspire::Mass::Element::MONO[:C] # carbon
Mspire::Mass::Subatomic::MONO[:electron]
```

### Isotopes and molecular formulas

```ruby
require 'mspire/isotope'
isotopes = Mspire::Isotope::ISOTOPES  # 288 isotopes
hydrogen_isotopes = isotopes.select {|iso| iso.element == :h }

c12 = Mspire::Isotope::BY_ELEMENT[:c].first
c12.atomic_number # also: mass_number atomic_mass relative_abundance average_mass
c12.mono   # => true (this is the monoisotopic isotope)

require 'mspire/molecular_formula'  # requires fftw gem
propane = Mspire::MolecularFormula['C3H8']
butane = propane + Mspire::MolecularFormula['CH2']
puts butane  # => C4H10

require 'mspire/isotope/distribution'  # requires fftw gem
puts butane.isotope_distribution  # :total, :max, :first as arg to normalize
```

### Digestion

```ruby
require 'mspire/digester'
trypsin = Mspire::Digester[:trypsin].
trypsin.digest("AACCKDDEERFFKPGG") # => ["AACCK", "DDEER", "FFKPGG"]
```
## TODO

* write the mzml index onto a file (along with correct SHA-1)
* implement spectrum unpack into an nmatrix or narray
* do a proper copy over of meta-data from mzml into imzml
* consider implementing params as a hash and formalizing more complete implementation agnostic params api

## Acronym

<i>M</i>ass <i>SP</i>ectrometry <i>I</i>n <i>R</i>uby.  Mspire originally stood for <i>M</i>ass <i>S</i>pectrometry <i>P</i>roteomics <i>I</i>n <i>R</i>uby but the library has since proven useful for all kinds of mass spectrometry projects, hence the more inclusive form.  The <i>e</i> was originally included for aesthetic reasons, but it also provides the user/developer the ability to attach whatever <i>E</i>xclamation or <i>E</i>pithet they choose to the acronym (the best ones will begin with <i>e</i> of course).

## Copyright

MIT license.  See LICENSE for details.

[Gem Version]: https://rubygems.org/gems/mspire
[Build Status]: https://travis-ci.org/princelab/mspire
[travis pull requests]: https://travis-ci.org/princelab/mspire/pull_requests
[Dependency Status]: https://gemnasium.com/princelab/mspire
[Code Climate]: https://codeclimate.com/github/princelab/mspire

[GV img]: https://badge.fury.io/rb/mspire.png
[BS img]: https://travis-ci.org/princelab/mspire.png
[DS img]: https://gemnasium.com/princelab/mspire.png
[CC img]: https://codeclimate.com/github/princelab/mspire.png
