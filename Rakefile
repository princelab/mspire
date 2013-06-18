require "bundler/gem_tasks"

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

task :default => :spec

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "rubabel #{version}"
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
