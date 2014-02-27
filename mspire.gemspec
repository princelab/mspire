# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mspire/version'

Gem::Specification.new do |spec|
  spec.name          = "mspire"
  spec.version       = Mspire::VERSION
  spec.authors       = ["John T. Prince", "Simon Chiang"]
  spec.email         = ["jtprince@gmail.com"]
  spec.description   = %q{mass spectrometry proteomics, lipidomics, and tools, a rewrite of mspire, merging of ms-* gems}
  spec.summary       = %q{mass spectrometry proteomics, lipidomics, and tools}
  spec.homepage      = "http://github.com/princelab/mspire"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  [
    ["nokogiri", "~> 1.6.1"],
    ["bsearch", ">= 1.5.0"],
    ["andand", ">= 1.3.3"],
    ["obo", ">= 0.1.4"],
    ["builder", "~> 3.2.2"],
    ["bio", "~> 1.4.3.0001"],
    ["trollop", "~> 2.0.0"],
  ].each do |args|
    spec.add_dependency(*args)
  end

  [
    ["bundler", "~> 1.5.1"],
    ["rake"],
    ["rspec", "~> 2.14.1"], 
    ["rdoc", "~> 4.1.0"], 
    ["simplecov", "~> 0.8.2"],
    ["coveralls"],
    # here because bad microsoft OS support
    ["fftw3", "~> 0.3"],
  ].each do |args|
    spec.add_development_dependency(*args)
  end

end
