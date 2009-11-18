#!/usr/bin/env ruby

require 'optparse'

def run(cmd)
  reply = `#{cmd}`
  if reply || reply != ""
    puts reply
  end
end

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
  op.banner = "usage: #{File.basename(__FILE__)} <project_name> <github_username>"
  op.separator "creates a new mspire package"
  op.separator "Designed to work with a project name like: ms-template "
  op.separator "giving 'ms/template' and Ms::Template"
  op.separator "assumes use of Jeweler"
  op.separator "OPTIONS (will fill in with [TODO: xxx] if missing"
  op.on("-a", "--author <string>", "the author of the package ('First Last')") {|v| opt[:author] = v }
  op.on("-e", "--email <string>", "email address of author") {|v| opt[:email] = v }
  op.on("-f", "--force", "write over files if necessary") {|v| $force = v }
  op.on("-t", "--template", "build the github template") {|v| opt[:template] = v }
end
opts.parse!

if ARGV.size != 2
  puts opts
  exit
end


(project, github_username) = ARGV

make_dir(project) do 
  tm = Time.now
  make_file("History") do
    %Q{
    == 0.0.1 / #{tm.year}-#{tm.month}-#{tm.day} 
    * initial version
    }
  end

  make_file("README.rdoc") do
    description = '{TODO: Description of the project}'
    examples = %Q{    require "#{project.gsub('-','/')}\n\n"    {TODO: example code!}}
    installation = %Q{    gem install #{project}}
        
    if opt[:template]
      description = ["gives the suggested layout for an mspire <tt>ms-<whatever></tt> package."]
      description << ""
      description << "<b>DO NOT MODIFY <tt>git@github.com:#{github_username}/#{project}.git</tt> directly!</b>  <em>Modify the generator described below, run it, and push the changes.</em>  Of course, if you clone this for a new project, you should modify it directly."
      description = description.join("\n")

      examples = ["This template can be used to start a fresh project by cloning it:"]
      examples << ""
      examples << "    git clone git@github.com:#{github_username}/#{project}.git"
      examples << ""
      examples << "Now you need to search and replace:"
      examples << ""
      examples << "    1. #{project} => <your project>"
      examples << "    2. #{opt[:author]} => <your name>"
      examples << "    3. <email address hidden> => <your email>"
      examples << "    4. (and some other minor changes to the specs)"
      examples << "    5. make sure the LICENSE is as you desire it"
      examples << ""
      examples << "Or, install the mspire gem (<tt>gem install mspire</tt>), go to the base directory of the gem and you will find a script in the 'script' folder: <em>#{File.basename(__FILE__)}</em>.  Run the script with no arguments for usage information."
      examples = examples.join("\n")

      installation = %Q{(You probably don't want to actually install the template.  See Examples above for cloning or generating a template for your mspire project)}

    end

    %Q{
= {#{project}}[http://#{github_username}.github.com/#{project}/rdoc/]

#{project} is an {mspire}[http:/jtprince.github.com/mspire/] library that #{description}

== Examples

#{examples}

== Installation

#{installation} 

== Copyright

See LICENSE.
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
    WEBSITE_BASE = "website"
    WEBSITE_OUTPUT = WEBSITE_BASE + "/output"

    gemspec = Gem::Specification.new do |s|
      s.name = NAME
      s.authors = ["#{opt[:author]}"]
      s.email = "#{opt[:email]}"
      s.homepage = "http://#{github_username}.github.com/" + NAME + "/"
      s.summary = "An mspire library [TODO: that does what?]"
      s.description = "[TODO: longer description]"
      s.rubyforge_project = 'mspire'
      # s.add_dependency("ms-core", ">= 0.0.2")
      # s.add_development_dependency("ms-testdata", ">= 0.18.0")
      s.add_development_dependency("bacon", ">= 1.1.0")
      s.files << "VERSION"
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
    } + %q{
    def rdoc_redirect(base_rdoc_output_dir, package_website_page, version)
      content = %Q{
    <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
    <html><head><title>mspire: } + NAME + %Q{rdoc</title>
    <meta http-equiv="REFRESH" content="0;url=#{package_website_page}/rdoc/#{version}/">
    </head> </html> 
      }
      FileUtils.mkpath(base_rdoc_output_dir)
      File.open(base_rdoc_output_dir + "/index.html", 'w') {|out| out.print content }
    end
    
    require 'rake/rdoctask'
    Rake::RDocTask.new do |rdoc|
      base_rdoc_output_dir = WEBSITE_OUTPUT + '/rdoc'
      version = File.read('VERSION')
      rdoc.rdoc_dir = 'rdoc'
      rdoc.title = NAME + ' ' + version
      rdoc.rdoc_files.include('README*')
      rdoc.rdoc_files.include('lib/**/*.rb')
    end

    task :create_redirect do
      base_rdoc_output_dir = WEBSITE_OUTPUT + '/rdoc'
      rdoc_redirect(base_rdoc_output_dir, gemspec.homepage,version)
    end

    namespace :website do
      desc "checkout and configure the gh-pages submodule (assumes you have it)"
      task :submodule_update do
        if File.exist?(WEBSITE_OUTPUT + "/.git")
          puts "!! not doing anything, #{WEBSITE_OUTPUT + "/.git"} already exists !!"
        else

          puts "(not sure why this won't work programmatically)"
          puts "################################################"
          puts "[Execute these commands]"
          puts "################################################"
          puts "git submodule init"
          puts "git submodule update"
          puts "pushd #{WEBSITE_OUTPUT}"
          puts "git co --track -b gh-pages origin/gh-pages ;"
          puts "popd"
          puts "################################################"

          # not sure why this won't work!
          #%x{git submodule init}
          #%x{git submodule update}
          #Dir.chdir(WEBSITE_OUTPUT) do
          #  %x{git co --track -b gh-pages origin/gh-pages ;}
          #end
        end
      end

      desc "setup your initial gh-pages"
      task :init_ghpages do
        puts "################################################"
        puts "[Execute these commands]"
        puts "################################################"
        puts "git symbolic-ref HEAD refs/heads/gh-pages"
        puts "rm .git/index"
        puts "git clean -fdx"
        puts 'echo "Hello" > index.html'
        puts "git add ."
        puts 'git commit -a -m "my first gh-page"'
        puts "git push origin gh-pages"
      end

    end

    task :default => :spec

    task :build => :gemspec

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
        proj_path = project.gsub('-','/')
        the_module = project.split('-').map {|v| v.capitalize }.join("::")
        path_up = "/.." * pieces.size
        %Q{
        require File.expand_path(File.dirname(__FILE__) + '#{path_up}/spec_helper.rb')

        require '#{proj_path}'

        # bacon usage:
        # http://chneukirchen.org/repos/bacon/README"
        describe 'a #{project}' do
          it 'has a version' do
            require '#{proj_path}/version'
            #{the_module}::VERSION.should.match /^\\d+\\.\\d+\\.\\d+$/
          end
        end
        }
      end
    end
  end

  puts "(Jeweler requires an active GIT repo for building packages properly)"
  puts "Initializing GIT repository"

  unless File.exist?(".git")
    run "git init"
    run "git add *"
    puts "Making first commit"
    run "git commit -m 'initial commit'"
  end

  make_dir("tmp") do 
    system 'git clone git@github.com:jtprince/ms-template ;'
    FileUtils.mv "ms-template/website", File.join(Dir.pwd, "../website")
  end
  FileUtils.rm_rf "tmp"

  

end # chdir


