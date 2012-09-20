$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'rubygems'
require 'rspec'

TESTFILES = File.dirname(__FILE__) + '/testfiles'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.color_enabled = true
  config.tty = true
  config.formatter = :documentation  # :progress, :html, :textmate
  #config.formatter = :progress # :progress, :html, :textmate
end


def benchmark(*args, &block)
  if ENV['BENCHMARK']
    Benchmark.bmbm(*args, &block)
  end
end

# given "filename.ext" returns "filename.CHECK.ext
# block can be given to sanitize each string
def file_check(filename, delete=true, &block)
  ext = File.extname(filename)
  base = filename.chomp(ext)
  checkfile = base + ".CHECK" + ext
  File.exist?(filename).should be_true
  fstring = IO.read(filename)
  cstring = IO.read(checkfile)
  if block
    (fstring, cstring) = [fstring, cstring].map do |string|
      block.call(string)
    end
  end
  fstring.should == cstring
  File.unlink(filename) if delete
end

def sanitize_mspire_version_xml(string)
  string.gsub(/"mspire(_[\d\.]+)?" version="([\.\d]+)"/, %Q{"mspire" version="X.X.X"})
  .gsub(/softwareRef="mspire_[\d\.]+/, 'softwareRef="mspire_X.X.X')
end

require 'stringio'
 
module Kernel
 
  def capture_stdout
    out = StringIO.new
    $stdout = out
    yield
    out.string
  ensure
    $stdout = STDOUT
  end

end

