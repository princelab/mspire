require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/gempackagetask'
require 'configurable'  # for cdoc
require 'yaml'
require 'ostruct'

NAME = 'mspire'
$:.unshift('lib') unless $:.include?('lib')
require NAME

# this is similar to the bones gem:
BaseGemspec = Gem::Specification.new do |s|
  s.name = NAME
  s.version = Kernel.const_get(NAME.capitalize).const_get('VERSION') # Module::VERSION
  s.authors = ["John Prince", "Simon Chiang"]
  s.email = "jtprince@gmail.com"
  s.homepage = 'http://mspire.rubyforge.org/'
  s.summary = "mass spectrometry proteomics in Ruby: umbrella gem to include commonly used functionality"
  s.rubyforge_project = "mspire"
  s.has_rdoc = false
  s.rdoc_options = %W{--main README.rdoc -S -N --title mspire}
  s.extra_rdoc_files = %w{README.rdoc MIT-LICENSE History}
  # lib will be included by default
  s.files = Dir["lib/**/*.rb"] + %W{README.rdoc MIT-LICENSE History}
end

GEMSPEC_FILE = "#{NAME}.gemspec"
CFG = YAML.load_file("mspire_packages.yml")

def gem_versions(regexp) 
  `rubyforge login`
  `rubyforge config mspire`
  hash = YAML.load_file("#{ENV['HOME']}/.rubyforge/auto-config.yml")
  doublets = hash['release_ids'].select {|k,v| k =~ regexp }
  doublets.map do |k,v| 
    gem = v.keys.first 
    version = gem.split('-').last.sub(/\.gem$/,'')
    [k, version]
  end
end

def gemspec_from_file
  data = File.read(GEMSPEC_FILE)
  spec = nil
  Thread.new { spec = eval("$SAFE = 3\n#{data}") }.join
  spec
end

def get_dependencies
  CFG.map do |pkg_hash|
    if pkg_hash['in_mspire_gem']
      pkg_hash['name']
    else
      nil
    end
  end.compact
end

def gemspec_with_dependencies
  dependencies = get_dependencies
  to_include = gem_versions(/^ms-/).select {|k,v| dependencies.include?(k) }
  to_include.each do |k,v|
    BaseGemspec.add_dependency(k, ">= #{v}")
  end
  BaseGemspec
end

desc "writes gemspec to file"
task :write_gemspec do
  File.open(NAME + ".gemspec", 'w') {|out| out.print gemspec_with_dependencies.to_ruby }
end

desc "prints all ms-* modules in rdoc list format"
task :mspire_modules_in_rdoc do
end

if gemspec_from_file.is_a? Gem::Specification
  # uses the .gemspec file
  pkg_task = Rake::GemPackageTask.new(gemspec_from_file) do |pkg|
    pkg.need_tar = true
  end
end

#
# Documentation tasks
#

desc 'Generate documentation.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  gs = BaseGemspec
  
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = BaseGemspec.name
  rdoc.main   = 'README.rdoc'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include( gs.extra_rdoc_files )
  rdoc.rdoc_files.include( gs.files.select {|file| file =~ /^lib.*\.rb$/} )
  
  # Using CDoc to template your Rdoc will result in configurations being
  # listed with documentation in a subsection following attributes.  Not
  # necessary, but nice.
  require 'cdoc'
  rdoc.template = 'cdoc/cdoc_html_template' 
  rdoc.options << '--fmt' << 'cdoc'
end

#
# Spec tasks
#

desc 'Default: Run specs.'
task :default => :spec

desc 'Run specs.'
Rake::TestTask.new(:spec) do |t|
  # can specify SPEC=<file>_spec.rb or TEST=<file>_spec.rb
  ENV['TEST'] = ENV['SPEC'] if ENV['SPEC']  
  t.libs = ['lib']
  t.test_files = Dir.glob( File.join('spec', ENV['pattern'] || '**/*_spec.rb') )
  unless ENV['gems']
    #t.libs << 'submodule/ms-testdata/lib'
  end
  t.verbose = true
  t.warning = true
end


