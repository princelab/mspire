require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/gempackagetask'
require 'configurable'  # for cdoc

NAME = 'ms-core'

#
# Gem specification
#

def gemspec
  data = File.read("#{NAME}.gemspec")
  spec = nil
  Thread.new { spec = eval("$SAFE = 3\n#{data}") }.join
  spec
end

Rake::GemPackageTask.new(gemspec) do |pkg|
  pkg.need_tar = true
end

desc 'Prints the gemspec manifest.'
task :print_manifest do
  # collect files from the gemspec, labeling 
  # with true or false corresponding to the
  # file existing or not
  files = gemspec.files.inject({}) do |files, file|
    files[File.expand_path(file)] = [File.exists?(file), file]
    files
  end
  
  # gather non-rdoc/pkg files for the project
  # and add to the files list if they are not
  # included already (marking by the absence
  # of a label)
  Dir.glob("**/*").each do |file|
    next if file =~ /^(rdoc|pkg)/ || File.directory?(file)
    
    path = File.expand_path(file)
    files[path] = ["", file] unless files.has_key?(path)
  end
  
  # sort and output the results
  files.values.sort_by {|exists, file| file }.each do |entry| 
    puts "%-5s %s" % entry
  end
end

#
# Documentation tasks
#

desc 'Generate documentation.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  spec = gemspec
  
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = NAME
  rdoc.main   = 'README'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include( spec.extra_rdoc_files )
  rdoc.rdoc_files.include( spec.files.select {|file| file =~ /^lib.*\.rb$/} )
  
  # Using CDoc to template your Rdoc will result in configurations being
  # listed with documentation in a subsection following attributes.  Not
  # necessary, but nice.
  require 'cdoc'
  rdoc.template = 'cdoc/cdoc_html_template' 
  rdoc.options << '--fmt' << 'cdoc'
end

## NOT NECESSARY? now that doc should be automatically published to rdoc.info
#desc "Publish RDoc to RubyForge"
#task :publish_rdoc => [:rdoc] do
  #require 'yaml'
  
  #config = YAML.load(File.read(File.expand_path("~/.rubyforge/user-config.yml")))
  #host = "#{config["username"]}@rubyforge.org"
  
  #rsync_args = "-v -c -r"
  #remote_dir = "/var/www/gforge-projects/mspire/ms-core"
  #local_dir = "rdoc"
 
  #sh %{rsync #{rsync_args} #{local_dir}/ #{host}:#{remote_dir}}
#end

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


