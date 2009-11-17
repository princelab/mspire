#!/usr/bin/env ruby

require 'optparse'

# the block allows writing into the final module
def make_module(pieces, string="", klass=false, spaces=0, &block)
  name = pieces.shift
  margin = " " * spaces
  if name
    tp = klass ? 'class' : 'module'
    string << margin + "#{tp} #{name.capitalize}\n"
    spaces += 2
    make_module(pieces, string, false, spaces, &block)
    string << margin + "end\n"
  else
    string << block.call << "\n"
  end
end

def remove_margin(string)
  margin = 0
  string.each_line do |line|
    if md = /([^\s])/.match(line)
      margin = md.offset(1).first
    end
  end
  new_string = ""
  string.each_line do |line|
    if line[0...margin] =~ /[^\s]/
      raise 'something is left of your margin, either write something to deal with it or fix your margin'
    else
      new_string << (line[margin..-1] || "\n")
    end
  end
  new_string
end

def make_file(name, _remove_margin=true, &block)
  if File.exist?(name) && !$force
    puts "not writing over #{name} (use --force to overwrite)"
  else
    File.open(name, 'w') do |out| 
      if block.nil?
        out.print " "
      else
        string = block.call
        string = remove_margin(string) if _remove_margin
        out.print string
      end
    end
  end
end

# makes the directory and changes into it for the block
def make_dir(name, &block)
  FileUtils.mkpath name unless File.exist?(name)
  abort "#{name} must be a directory!" unless File.directory?(name)
  unless block.nil?
    Dir.chdir(name) do
      block.call
    end
  end
end

opt = {
  :author => "[TODO: AUTHOR]",
  :email => "[TODO: email]",
}
$force = false

opts = OptionParser.new do |op|
  op.banner = "usage: #{File.basename(__FILE__)} <name>"
  op.separator "<name> should probably be: ms-<something>"
  op.separator "assumes use of Jeweler"
  op.separator "OPTIONS (will fill in with [TODO: xxx] if missing"
  op.on("-a", "--author <string>", "the author of the package ('First Last')") {|v| opt[:author] = v }
  op.on("-e", "--email <string>", "email address of author") {|v| opt[:email] = v }
  op.on("-f", "--force", "write over files if necessary") {|v| $force = v }
end
opts.parse!

if ARGV.size != 1
  puts opts
  exit
end


project = ARGV.shift

make_dir(project) do 
  tm = Time.now
  make_file("History") do
    %Q{
    == 0.0.1 / #{tm.year}-#{tm.month}-#{tm.day} 
    * initial version
    }
  end

  make_file("README.rdoc") do
    %Q{
    = {#{project}}[http:/mspire.rubyforge.org/projects/#{project}]

    #{project} is an {mspire}[http:/mspire.rubyforge.org/] library that ... {TODO: Description of the project}

    == Examples

        require "#{project.gsub('-','/')}"

        {TODO: example code!}

    == Installation

        gem install #{project}

    == Copyright

    See LICENSE.
    README
    }
  end

  make_file("LICENSE") do
    %Q{
    (The MIT License)

    Copyright (c) #{Time.now.year} #{opt[:author]}

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.
    LICENSE
    }
  end

  make_file("VERSION") do
    '0.0.1'
  end

  make_file("Rakefile") do
    %Q{
    require 'rubygems'
    require 'rake'
    require 'jeweler'
    require 'rake/testtask'
    require 'rcov/rcovtask'

    NAME = "#{project}"

    gemspec = Gem::Specification.new do |s|
      s.name = NAME
      s.authors = ["#{opt[:author]}"]
      s.email = "#{opt[:email]}"
      s.homepage = "http://mspire.rubyforge.org/projects/" + NAME + "/"
      s.summary = "An mspire library [TODO: that does what?]"
      s.description = "[TODO: longer description]"
      # s.add_dependency("ms-core", ">= 0.0.2")
      # s.add_development_dependency("ms-testdata", ">= 0.18.0")
      s.add_development_dependency("bacon", ">= 1.1.0")
    end

    Jeweler::Tasks.new(gemspec)

    Rake::TestTask.new(:spec) do |spec|
      spec.libs << 'lib' << 'spec'
      spec.pattern = 'spec/**/*_spec.rb'
      spec.verbose = true
    end

    Rcov::RcovTask.new do |spec|
      spec.libs << 'spec'
      spec.pattern = 'spec/**/*_spec.rb'
      spec.verbose = true
    end

    require 'rake/rdoctask'
    Rake::RDocTask.new do |rdoc|
      version = File.read('VERSION')
      rdoc.rdoc_dir = 'rdoc'
      rdoc.title = NAME + ' ' + version
      rdoc.rdoc_files.include('README*')
      rdoc.rdoc_files.include('lib/**/*.rb')
    end

    task :spec => :check_dependencies

    task :default => :spec

    # credit: Rakefile modeled after Jeweler's
    }
  end # make_file("Rakefile")

  pieces = project.split('-')
  all_pieces = pieces.map
  file_base = pieces.pop
  proj_dir_path = pieces.join("/")

  make_dir("lib") do
    make_dir(proj_dir_path) do
      make_file(file_base + '.rb')
      make_dir(file_base) do
        make_file('version.rb', false) do
          make_module(all_pieces) do
            updir = '/..' * (pieces.size+2)
            %Q{    VERSION = IO.readlines(File.dirname(__FILE__) + "#{updir}/VERSION").first.chomp}
          end
        end
      end
    end
  end

  make_dir("spec") do
    make_file("spec_helper.rb") do
      %Q{
      require 'rubygems'
      require 'bacon'

      $LOAD_PATH.unshift(File.dirname(__FILE__))
      $LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

      Bacon.summary_on_exit
      }
    end

    make_dir(proj_dir_path) do
      make_file(file_base + "_spec.rb") do
        path_up = "/.." * pieces.size
        %Q{
        require File.expand_path(File.dirname(__FILE__) + '#{path_up}/spec_helper.rb')

        require '#{project.gsub('-','/')}'

        describe 'a #{project}' do
          # http://chneukirchen.org/repos/bacon/README"
          it 'works like a charm!' do
            x = 29
            x.should.equal 29
            x.should.flunk "you need to write some specs!"
          end
        end
        }
      end
    end
  end


end # chdir


