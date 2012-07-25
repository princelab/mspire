# mspire

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

Mspire is the *only* converter from mzml into imzml.  

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

### mzml

    require 'ms/mzml'

    MS::Mzml.open("somefile.mzml") do |mzml|
      spectrum = mzml[0]   # the first spectrum ( same as mzml.spectrum(0) )
      spectrum = mzml["controllerType=0 controllerNumber=1 scan=2"]  # query by id string
      mzml.spectrum_from_scan_num(23) # raises ScanNumbersNotFound or ScanNumbersNotUnique errors if problems
    end

    require 'ms/mass/aa'

    MS::Mass::AA::MONO['A'] # or access by symbol

## Acronym

<i>M</i>ass <i>SP</i>ectrometry <i>I</i>n <i>R</i>uby.  Mspire originally stood for <i>M</i>ass <i>S</i>pectrometry <i>P</i>roteomics <i>I</i>n <i>R</i>uby but the library has since proven useful for all kinds of mass spectrometry projects, hence the more inclusive form.  The <i>e</i> was originally included for aesthetic reasons, but it also provides the user/developer the ability to attach whatever <i>E</i>xclamation or <i>E</i>pithet they choose to the acronym (the best ones will begin with <i>e</i> of course).

## Copyright

MIT license.  See LICENSE for details.
