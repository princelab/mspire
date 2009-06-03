# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{mspire}
  s.version = "0.6.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["John Prince", "Simon Chiang"]
  s.date = %q{2009-06-03}
  s.email = %q{jtprince@gmail.com}
  s.extra_rdoc_files = ["README.rdoc", "MIT-LICENSE", "History"]
  s.files = ["lib/mspire.rb", "README.rdoc", "MIT-LICENSE", "History"]
  s.homepage = %q{http://mspire.rubyforge.org/}
  s.rdoc_options = ["--main", "README.rdoc", "-S", "-N", "--title", "mspire"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{mspire}
  s.rubygems_version = %q{1.3.2}
  s.summary = %q{mass spectrometry proteomics in Ruby: umbrella gem to include commonly used functionality}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<ms-unimod>, ["= 0.1.0"])
      s.add_runtime_dependency(%q<ms-core>, ["= 0.0.1"])
      s.add_runtime_dependency(%q<ms-in_silico>, ["= 0.3.0"])
      s.add_runtime_dependency(%q<ms-msrun>, ["= 0.0.1"])
      s.add_runtime_dependency(%q<ms-fasta>, ["= 0.1.0"])
    else
      s.add_dependency(%q<ms-unimod>, ["= 0.1.0"])
      s.add_dependency(%q<ms-core>, ["= 0.0.1"])
      s.add_dependency(%q<ms-in_silico>, ["= 0.3.0"])
      s.add_dependency(%q<ms-msrun>, ["= 0.0.1"])
      s.add_dependency(%q<ms-fasta>, ["= 0.1.0"])
    end
  else
    s.add_dependency(%q<ms-unimod>, ["= 0.1.0"])
    s.add_dependency(%q<ms-core>, ["= 0.0.1"])
    s.add_dependency(%q<ms-in_silico>, ["= 0.3.0"])
    s.add_dependency(%q<ms-msrun>, ["= 0.0.1"])
    s.add_dependency(%q<ms-fasta>, ["= 0.1.0"])
  end
end
