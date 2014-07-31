require "bundler/gem_tasks"
 
@module_name = Mspire
@gem_name = 'mspire'
@gem_path_name = @gem_name.gsub('-','/')
 
require "#{@gem_path_name}/version"
 
require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end
 
task :default => :spec
 
require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = @module_name.const_get('VERSION')
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "#{@gem_name} #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

