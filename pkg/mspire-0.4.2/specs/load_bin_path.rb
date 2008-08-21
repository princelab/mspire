tmp = $VERBOSE ; $VERBOSE = nil
LOAD_BIN_PATH = File.expand_path(File.dirname(__FILE__) + "#{File::SEPARATOR}..#{File::SEPARATOR}bin")
$VERBOSE = tmp

if ENV.key?("PATH")
  ENV["PATH"] =  LOAD_BIN_PATH + File::PATH_SEPARATOR + ENV["PATH"]
end
