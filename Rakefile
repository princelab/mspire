require 'rake'
require 'rubygems'
require 'rake/rdoctask'
require 'rake/gempackagetask'
require 'rake/clean'
require 'fileutils'
require 'spec/rake/spectask'

###############################################
# GLOBAL
###############################################
FL = FileList

NAME = "mspire"

$dependencies = %w(libjtp)
$tfiles_large = 'test_files_large'
changelog = "changelog.txt"

core_files = FL["INSTALL", "README", "README.rdoc", "Rakefile", "LICENSE", changelog, "release_notes.txt", "{lib,bin,script,specs,tutorial,test_files}/**/*"]
big_dist_files = core_files + FL["test_files_large/**/*"]

dist_files = core_files 
# dist_files = big_dist_files

###############################################
# ENVIRONMENT
###############################################

ENV["OS"] == "Windows_NT" ? WIN32 = true : WIN32 = false
$gemcmd = "gem"
if WIN32
  unless ENV["TERM"] == "cygwin"
    $gemcmd << ".cmd"
  end
end

###############################################
# DOC
###############################################

def move_and_add_webgen_header(file, newfile, src_dir, heading)
  string = IO.read file
  with_header = heading + string
  File.open(newfile, 'w') {|v| v.print with_header }
  FileUtils.mv newfile, src_dir, :force => true
end

desc "copy top level files into doc/src"
task :cp_top_level_docs do
  string = "---
title: TITLE
inMenu: true
directoryName: mspire 
---\n"
  src = "doc/src"
  move_and_add_webgen_header('README', 'index.page', src, string.sub('TITLE', 'Home'))
  move_and_add_webgen_header('INSTALL', 'index.page', src + '/install', string.sub('TITLE', 'Install').sub('mspire', 'Install').sub("inMenu: true\n", ''))
end

desc "upload docs (doc/output) to server"
task :upload_docs do
  sh "scp -i ~/.ssh/rubyforge_key -r doc/output/* jtprince@rubyforge.org:/var/www/gforge-projects/mspire/"
end

# best to use webgen 0.3.8 right now
# to get working (may not require all these steps):
#    gem install RedCloth
#    gem install BlueCloth
#    soft link the bluecloth binary into path
desc "creates docs in doc/html"
task :html_docs => [:cp_top_level_docs] do
  FileUtils.cd 'doc' do
    sh "webgen"
  end
  FileUtils.cp 'doc/src/archive/t2x', 'doc/output/archive/t2x'
end

desc "does html_docs and rdoc and puts rdoc inside html_docs"
task :all_docs => [:html_docs, :rdoc] do
  FileUtils.mv 'html', 'doc/output/rdoc'
end

#rdoc_options = ['--main', 'README', '--title', NAME]
rdoc_options = ['--main', 'README.rdoc', '--title', NAME]
#rdoc_extra_includes = ["README", "INSTALL", "LICENSE"]
rdoc_extra_includes = ['README.rdoc']

Rake::RDocTask.new do |rd|
  rd.main = "README.rdoc"
  rd.rdoc_files.include("lib/**/*.rb", *rdoc_extra_includes )
  rd.options.push( *rdoc_options )
end

###############################################
# TESTS
###############################################

namespace :spec do
  task :autotest do
    require './specs/rspec_autotest'
    RspecAutotest.run
  end
end


task :ensure_dependencies do
  $dependencies.each do |dep|
    unless `#{$gemcmd} list -l #{dep}`.include?(dep)
      abort "ABORTING: install #{dep} before testing!"
    end
  end
end

task :ensure_large_testfiles do
  if !File.exist?($tfiles_large) and !ENV['SPEC_LARGE'].nil?
    warn "Not running with large files since #{$tfiles_large} does not exist!"
    warn "Removing SPEC_LARGE from ENV!"
    ENV.delete('SPEC_LARGE')
  end
end

task :ensure_gem_is_uninstalled do
  reply = `#{$gemcmd} list -l #{NAME}`
  if reply.include? NAME + " ("
    puts "GOING to uninstall gem '#{NAME}' for testing"
    if WIN32
      %x( #{$gemcmd} uninstall -x #{NAME} )
    else
      %x( sudo #{$gemcmd} uninstall -x #{NAME} )
    end
  end
end

desc "Run all specs"
Spec::Rake::SpecTask.new('spec') do |t|
  Rake::Task[:ensure_gem_is_uninstalled].invoke
  Rake::Task[:ensure_dependencies].invoke
  Rake::Task[:ensure_large_testfiles].invoke
  t.libs = 
    if !ENV['LIB'].nil?
      [ENV['LIB']]
    else
      ['lib']
    end
  #t.ruby_opts = ['-I', 'lib']
  t.spec_files = FileList['specs/**/*_spec.rb']
end

desc "Run all specs"
Spec::Rake::SpecTask.new('specl') do |t|
  Rake::Task[:ensure_gem_is_uninstalled].invoke
  Rake::Task[:ensure_dependencies].invoke
  Rake::Task[:ensure_large_testfiles].invoke
  t.spec_files = FileList['specs/**/*_spec.rb']
  t.libs = 
    if !ENV['LIB'].nil?
      [ENV['LIB']]
    else
      ['lib']
    end
  #t.libs = ['lib']
  #t.ruby_opts = ['-I', 'lib']
  t.spec_opts = ['--format', 'specdoc' ]
end

desc "Run all specs with RCov"
Spec::Rake::SpecTask.new('rcov') do |t|
  Rake::Task[:ensure_gem_is_uninstalled].invoke
  Rake::Task[:ensure_dependencies].invoke
  Rake::Task[:ensure_large_testfiles].invoke
  t.spec_files = FileList['specs/**/*_spec.rb']
  t.rcov = true
  t.libs = 
    if !ENV['LIB'].nil?
      [ENV['LIB']]
    else
      ['lib']
    end
  #t.ruby_opts = ['-I', 'lib']
  t.rcov_opts = ['--exclude', 'specs']
end

task :speci => [:ensure_gem_is_uninstalled, :ensure_dependencies, :ensure_large_testfiles] do
  # files that match a key word
  files_to_run = ENV['SPEC'] || FileList['specs/**/*_spec.rb']
  if ENV['SPECM']
    files_to_run = files_to_run.select do |file|
      file.include?(ENV['SPECM'])
    end
  end
  lib = 
    if !ENV['LIB'].nil?
      ENV['LIB']
    else
      'lib'
    end
  files_to_run.each do |spc|
    puts "------ SPEC=#{spc} ------"
    system "ruby -I #{lib} -S spec #{spc} --format specdoc"
  end
end

#Spec::Rake::SpecTask.new(:spec) do |t|
#  uninstall_gem
#  t.spec_files = FileList['spec/**/spec_*.rb']
#  t.libs = FileList['lib']
#  t.spec_opts = ['--format', 'specdoc']
#end


#desc "Run unit tests."
#Rake::TestTask.new do |t|
#  uninstall_gem
#  #  t.libs << "lib"  ## done by default
#  t.test_files = FL["test/tc_*.rb"]
#  #t.verbose = true
#end



#desc "Run unit tests individual on each test"
#task :test_ind do |t|
#  reply = `#{$gemcmd} list -l #{NAME}`
#  if reply.include? NAME + " ("
#    %x( sudo #{$gemcmd} uninstall -x #{NAME} )
#  end
#
#  #  t.libs << "lib"  ## done by default
#  test_files = FL["test/tc_*.rb"]
#  test_files.each do |file|
#    puts "TESTING: #{file.sub(/test\//,'')}"
#    puts `ruby -I lib #{file}`
#  end
#  #t.verbose = true
#end





#desc "Run all tests"
#task :test_indiv do
#  sys.cd "test" do 
#    sys["tc_*.rb"].each do |file|
#      sys "ruby #{file}"
#    end
#  end
#end

###############################################
# PACKAGE / INSTALL / UNINSTALL
###############################################

## To release a package on rubyforge:
## Login to rubyforge and go the 'Files' tab
## then "To create a new release click here"

tm = Time.now
spec = Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.name = NAME
  s.version = IO.readlines(changelog).grep(/##.*version/).pop.split(/\s+/).last.chomp 
  s.summary = "Mass Spectrometry Proteomics Objects, Scripts, and Executables"
  s.date = "#{tm.year}-#{tm.month}-#{tm.day}"
  s.email = "jprince@icmb.utexas.edu"
  s.homepage = "http://mspire.rubyforge.org"
  s.rubyforge_project = "mspire"
  s.description = "mspire is for working with mass spectrometry proteomics data"
  s.has_rdoc = true
  s.authors = ["John Prince"]
  s.files = dist_files
  s.rdoc_options = rdoc_options
  s.extra_rdoc_files = rdoc_extra_includes
  s.executables = FL["bin/*"].map {|file| File.basename(file) }
  s.add_dependency('libjtp', '~> 0.2.14')
  s.add_dependency('axml', '~> 0.0.0')
  s.add_dependency('arrayclass', '~> 0.1.0')
  s.requirements << '"libxml" is the prefered xml parser right now.  libxml, xmlparser, REXML and regular expressions are used as fallback in some routines.'
  s.requirements << 'some plotting functions will not be available without the "gnuplot" gem (and underlying gnuplot binary)'
  s.requirements << 'the "t2x" binary (in archive) or readw.exe is required to convert .RAW files to mzXML in some applications'
  s.requirements << '"rake" is useful for development'
  s.requirements << '"webgen (with gems redcloth and bluecloth) is necessary to build web pages'
  #s.test_files = FL["test/tc_*.rb"]
  s.test_files = FL["specs/**/*_spec.rb"]
end

desc "Create packages."
Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end

#desc "Create packages."
#gen RubyPackage, NAME do |t|
#  t.version = "0.1.4"
#  t.summary = "Mass Spectrometry Proteomics Objects, Scripts, and Executables"
#  t.files = dist_files
#  t.bindir = "bin"
#  t.executable = sys["bin/*"].collect {|file| File.basename(file) }
#  t.test_files = sys["test/tc_*.rb"]
#  t.gem_add_dependency('libjtp', '= 0.1.1')
#  t.package_task
#end

task :remove_pkg do 
  FileUtils.rm_rf "pkg"
end

task :install => [:reinstall]

desc "uninstalls the package, packages a fresh one, and installs"
task :reinstall => [:remove_pkg, :clean, :package] do
  reply = `#{$gemcmd} list -l #{NAME}`
  if reply.include?(NAME + " (")
    %x( #{$gemcmd} uninstall -x #{NAME} )
  end
  FileUtils.cd("pkg") do
    %x( #{$gemcmd} install #{NAME}*.gem )
  end
  
end

###############################################
# CLEANUP
###############################################

#desc "Remove autogenerated and backup files."
#gen Clean
#var[:clean].include "pkg", "*~", tutorial_files
