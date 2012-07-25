# mspire

Tools for working with mass spectrometry data in ruby.  If you use mspire in
association with a publication, please cite:

Prince JT, Marcotte EM. Bioinformatics. 2008 Dec 1;24(23):2796-7. ([pubmed](http://www.ncbi.nlm.nih.gov/pubmed/18930952))

## Features

Mspire is a full featured library for working with mass spectrometry data
(e.g., proteomics and metabolomics/lipidomics).

### mzml

Mspire is the *only* mzml reader/writer with random access and full implicit
object model resolution.

* Fast
* Reading *and* writing
* True random access to spectra or chromatograms
* Complete object model
* Complete object link resolution (even with random access)
* Complete support for controlled vocabulary (CV) params
* Simplified CV param creation
* Complete support for referenceable param groups and user params
* Supports zlib compressed binary data
* Can easily create custom mzml files from any data source

### imzml

Mspire has the *only* converter from mzml into imzml.  

* gracefully handles SIM data
* handles both processed and continuous modes

### Protein Digestion

* Support for 32 enzymes/variants by name
* Customizable enzymes
* Can digest or return digestion sites

### Isotope Distribution Prediction

* fastest method known (FFT convolution)

### Fasta files

* complete programmatic access to description (aka header) lines (via bio-ruby)
* create a peptide centric DB

### Peaklists

* merging/summing and splitting algorithms

### OBO

* Ontology hash access
* Rake task to auto-update ontologies (so they are always current)

### Molecular Formulas

* can +,-,*,/ formulas

### Misc

* calculates q-values

### PepXML

* Full object model and complete writing support
* Basic search hit reading support

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

*M*ass *SP*ectrometry *I*n *R*uby.  Mspire originally stood for *M*ass *S*pectrometry *P*roteomics *I*n *R*uby in Ruby but the library has since proven useful for all kinds of mass spectrometry projects, hence the more inclusive form.  The *e* was originally included for aesthetic reasons, but it also provides the user/developer the ability to attach whatever *E*xclamation or *E*pithet they choose to the acronym (the best ones will begin with *e* of course).

## Copyright

See LICENSE (MIT)
