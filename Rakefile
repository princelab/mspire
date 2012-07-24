require 'rubygems'
require 'rake'
require 'rspec/core/rake_task'
require 'yard'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "mspire"
  gem.homepage = "http://github.com/princelab/mspire"
  gem.license = "MIT"
  gem.summary = %Q{mass spectrometry proteomics, lipidomics, and tools}
  gem.description = %Q{mass spectrometry proteomics, lipidomics, and tools, a rewrite of mspire, merging of ms-* gems}
  gem.email = "jtprince@gmail.com"
  gem.authors = ["John T. Prince", "Simon Chiang"]
  gem.add_dependency "nokogiri", "~> 1.5"
  gem.add_dependency "bsearch", ">= 1.5.0"
  gem.add_dependency "andand", ">= 1.3.1"
  gem.add_dependency "obo", ">= 0.1.0"
  gem.add_dependency "builder", "~> 3.0.0"
  gem.add_dependency "bio", "~> 1.4.2"
  gem.add_dependency "trollop", "~> 1.16.2"
  gem.add_dependency "uuid", ">= 2.3.5"
  # this should be a real dependency, but need to document getting this
  # working on windows first!
  gem.add_development_dependency "fftw3", "~> 0.3"
  gem.add_development_dependency "rspec", "~> 2.6"
  gem.add_development_dependency "jeweler", "~> 1.5.2"
  #gem.add_development_dependency "rcov", ">= 0"
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

YARD::Rake::YardocTask.new do |t|
  t.files   = ['lib/**/*.rb', 'obo/**/*', 'README.md', 'script/**/*']   # optional
  #t.options = ['--any', '--extra', '--opts'] # optional
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

#require 'rcov/rcovtask'
#Rcov::RcovTask.new do |spec|
#  spec.libs << 'spec'
#  spec.pattern = 'spec/**/*_spec.rb'
#  spec.verbose = true
#end

task :default => :spec

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "mspire #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

desc "downloads the latest obo to appropriate spot"
task 'obo-update' do
  require 'mspire/mzml/cv'
  require 'open-uri'
  Mspire::Mzml::CV::DEFAULT_CVS.each do |const|
    obo_fn = File.dirname(__FILE__) + "/obo/#{const.id.downcase}.obo"
    File.write(obo_fn, open(const.uri, &:read).gsub(/\r\n?/, "\n"))
    puts "NOTE: if a file changed (git status), then update lib/mspire/mzml/cv.rb with correct version !!!"
  end
end
