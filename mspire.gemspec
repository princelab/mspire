Gem::Specification.new do |s|
  s.name = "mspire"
  s.version = "0.6.0"
  s.authors = ["Simon Chiang", "John Prince"]
  s.email = "jtprince@gmail.com"
  s.homepage = "http://mspire.rubyforge.org/"
  s.platform = Gem::Platform::RUBY
  s.summary = "mass spectrometry proteomics in Ruby: umbrella gem to include commonly used functionality"
  #s.require_path = "lib"
  s.rubyforge_project = "mspire"
  s.has_rdoc = false


  s.rdoc_options.concat %W{--main README -S -N --title mspire}
  
  # list extra rdoc files like README here.
  s.extra_rdoc_files = %W{
    README
    MIT-LICENSE
    History
  }
  
  # list the files you want to include here. you can
  # check this manifest using 'rake :print_manifest'
  s.files = %W{
    mspire.gemspec
    README.rdoc

  }

  ## -- all add_dependency lines are auto-generated based on dependencies.yml -- ##
  s.add_dependency("ms-unimod","= 0.1.0")
  s.add_dependency("ms-core","= 0.0.1")
  s.add_dependency("ms-in_silico","= 0.3.0")
  s.add_dependency("ms-fasta","= 0.1.0")
  s.add_dependency("ms-msrun","= 0.0.1")
end
