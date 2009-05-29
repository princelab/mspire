gem 'rspec'


# a global flag that lets me know what format we're dealing with for output
$specdoc = false
## something changed between version 1.0.6?? and 1.1.1 in rspec so that
#Spec::Runner is no longer an object being created...
#ObjectSpace.each_object do |obj|
#  case obj
#  when Spec::Runner::Formatter::SpecdocFormatter
#    $specdoc = true
#  end
#end

# Set up some global testing variables:
#silent {
  ROOT_DIR = File.dirname(__FILE__) + '/..'
  SPEC_DIR = File.dirname(__FILE__)

  Tfiles = File.dirname(__FILE__) + '/../test_files'
  Tfiles_l = File.dirname(__FILE__) + '/../test_files_large'
  Tfiles_large = Tfiles_l
#}

# this variable is for large files!
if ENV['SPEC_LARGE']
  $spec_large = true
else
  #[NOTE: NOT testing with large test files]"
  # ** run with env var: SPEC_LARGE and ensure tfiles_large dir"
  $spec_large = false
end

def spec_large(&block)
  if $spec_large
    block.call
  else
    # Requires SPEC_LARGE=true and tfiles_large dir for testing large test files
    it 'SKIPPING (not testing large files)' do
    end
  end
end

# returns all output to stdout as a string
# will respond to is_a? File -> false is_a? IO true even though it is really a
# file
def capture_stdout(&block)
  capture_file = Tfiles + '/capture_stdout.tmp'
  def capture_file.is_a?(klass)
    case klass.to_s
    when 'IO'
      true
    when 'File'
      false
    else
      false
    end
  end
  $stdout = File.open(capture_file, 'w')
  block.call
  $stdout.close
  $stdout = STDOUT
  string = IO.read(capture_file)
  File.unlink capture_file
  string
end

require 'ostruct'
# class for using a ruby-ish initializer
class MyOpenStruct < OpenStruct
  def initialize(*args) 
    super(*args)
    if block_given?
      yield(self)
    end
  end
end


def xdescribe(*args)
  puts "describe: #{args.join(' ')}"
  puts "**SKIPPING**"
end

def Xdescribe(*args)
  xdescribe(*args)
end

def xit(*args)
  puts "\n- SKIPPING: #{args.join(' ')}"
end

def it_should(*args)
  string = "- WRITE TEST: #{args.join(' ')}"
  if $specdoc
    puts(string)
  else
    puts("\n" + string)
  end
end

def silent(&block)
  tmp = $VERBOSE ; $VERBOSE = nil
  block.call
  $VERBOSE = tmp
end


require SPEC_DIR + '/load_bin_path'

class String
  #alias_method :exist?, exist_as_a_file?
  #alias_method exist_as_a_file?, exist?
  #def exist?
  #  File.exist? self
  #end
  def exist_as_a_file?
    File.exist? self
  end
end

describe "a cmdline program", :shared => true do
  before(:all) do
    testdir = File.dirname(__FILE__)
    libdir = testdir + '/../lib'
    bindir = testdir +  '/../bin'
    @cmd = "ruby -I #{libdir} #{bindir}/#{@progname} "
  end

  it 'gives usage when called with no args' do
    reply = `#{@cmd}`
    reply.should =~ /usage/i
  end

end
