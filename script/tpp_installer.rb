#!/usr/bin/ruby -w

###########################################################
# GLOBAL CONFIG:

## SYSTEM SPECIFIC VARIABLES:
BIN_DIR = '/usr/bin/'
NICE_PATH = '/usr/bin/nice' # path to nice program on your system

## APACHE VARIABLES:
MODS_AVAILABLE = '/etc/apache2/mods-available/include.load'
MODS_ENABLED = '/etc/apache2/mods-enabled/include.load'
# A File that will be included by the webserver to add specific directives:
TPP_CONF = '/etc/apache2/conf.d/tpp.conf'
# The system call to restart your apache
RESTART_APACHE = '/etc/init.d/apache2 restart'

## SETUP YOUR TPP INSTALL:
TPP_INSTALL = "/work/tpp"   # directory to hold TPP executables, etc.
# (where TPP_ROOT will actually go)
TPP_DATA_PATH = "/work/tpp-data" # directory to hold your tpp data files

TPP_WEB = '/tpp/'
TPP_ISB_DEF_DIR = '/tools/bin/TPP/'
TPP_ISB_DIR = 'tpp' # DON'T change this

WEBSERVER_ROOT = '/var/www'
TPP_WEB_PATH_STUB = WEBSERVER_ROOT # real directory to make soft link inside
# For security reasons, TPP_VIS_PATH should NOT be the same as TPP_DATA_PATH
TPP_VIS_PATH = WEBSERVER_ROOT + '/tpp-vis/'
TPP_DATA_PATH_SOFT_LINK = WEBSERVER_ROOT + '/tpp'
#TPP_WEB_PATH = WEBSERVER_ROOT + TPP_DATA_PATH_SOFT_LINK

## VARIABLES YOU PROBABLY DON'T WANT TO CHANGE:
XINTERACT_WRAPPER = 'xinteract'
XINTERACT_ISB = 'xinteract-isb'
makefile_incl = 'src/Makefile.incl'
sequest2xml = 'src/Parsers/Algorithm2XML/Sequest2XML/Sequest2XML.cxx'

### VARIABLES YOU PROBABLY SHOULDN'T CHANGE UNLESS YOU MODIFY the config
### scripts
HARD_CODED_TPP_INSTALL = '/tools/bin/TPP/tpp/'
TPP_ROOT = HARD_CODED_TPP_INSTALL
HARD_CODED_TPP_INSTALL_STUB = '/tools/bin/TPP' # real dir to hold soft link 
###########################################################

require 'fileutils'

#######################################################
# SUBROUTINES:
#######################################################


# creates the file with the given contents unless the file already exists AND already contains the contents
def make_file(file, string)
  puts "Trying to make file: #{file}"
  if File.exist?(file) && string == IO.read(file) 
    puts "File already exists with the given string" 
  else
    puts "Made file with given string"
    File.open(file, "w") { |out| out.print string }
  end
end

def mkpath(mpath)
  path = mpath.chomp('/')
  if File.exist? path; puts "Dir #{path} exists"
  else 
    FileUtils.mkpath path
    puts "CREATING #{path}"
  end
end

def chmod(code, path)
  printf("Changing mode of #{path} to %o", code)
  FileUtils.chmod code, path 
end

# creates wrapper around xinteract that runs #{XINTERACT_ISB} and moves files
# to #{TPP_VIS_PATH}
def xinteract_wrapper
  tpp_data_path_wts = TPP_DATA_PATH.chomp('/')+'/'
  "# Runs xinteract with whatever command lines given
  # And then moves shtml files to #{TPP_VIS_PATH}
  #{XINTERACT_ISB} $@
  ruby -e 'if Dir[\"#{tpp_data_path_wts}*.shtml\"].size > 0 ; system \"mv #{tpp_data_path_wts}*.shtml #{TPP_VIS_PATH}\"; puts \"moving #{tpp_data_path_wts}*.shtml to #{TPP_VIS_PATH} for webserver security.\" end' 
  ".gsub(/^\s+/,'')
end

def swap_line(file, regex, newval)
  puts "EDITING: #{file}"
  tmpfile = "tmp.tmp"
  File.open(tmpfile, "w") do |out|
    out.puts IO.readlines(file).collect{|line| line.sub(regex, newval) }
  end
  File.rename(tmpfile, file)
end
#{tpp_data_path_wts}*.shtml
def soft_link(mtarget, mlink)
  (link,target) = [mlink,mtarget].collect {|t| t.chomp('/')} 
  if File.exist? link ;#{tpp_data_path_wts}*.shtml puts "Link #{link} exists!"
  else
    FileUtils.ln_sf target, link
    puts "CREATING soft link: #{link} -> #{target}"
  end
end

def sys(string)
  puts "PERFORMING: #{string}"
  puts `#{string}`
end

def modify_and_restart_apache(tpp_root, webserver_root, tpp_vis_path, mods_avail, mods_enab)
  # APACHE:
  soft_link(mods_avail, mods_enab)

  conf_string = <<END_DOC
#
# ISB-Tools Trans Proteomic Pipeline directive
#

Alias /tpp/html \"#{tpp_root}html\"
<Directory \"#{tpp_root}html\">
    AllowOverride None
    Options Includes Indexes FollowSymLinks MultiViews
    Order allow,deny
    Allow from all
</Directory>

<Directory \"#{tpp_root}schema\">
    AllowOverride None
    Options Includes Indexes FollowSymLinks MultiViews
    Order allow,deny
    Allow from all
</Directory>

ScriptAlias /tpp/cgi-bin/ \"#{tpp_root}cgi-bin/\"
<Directory \"#{tpp_root}cgi-bin\">
    AllowOverride AuthConfig Limit
    Options ExecCGI
    Order allow,deny
    Allow from all
    SetEnv WEBSERVER_ROOT #{webserver_root}
</Directory>

<Directory \"#{tpp_vis_path}\">
  Options Includes
</Directory>

END_DOC

  make_file(TPP_CONF, conf_string)
  sys "#{RESTART_APACHE}"
end



###############################################################
# MAIN
###############################################################

if ARGV.size < 1
  puts "
  usage: #{File.basename(__FILE__)} trans_proteomic_pipeline_dir

  Will install tpp on a ubuntu system (perhaps a debian system, too?).  With
  slight modifications, you may get this to install on other machines.
  Requires apache2 (sudo apt-get apache2).  The installation uses all the
  default TPP locations because a lot of these are quite hard-coded in the tpp
  despite the config files they use.  Instead, soft-links are made so that you
  can configure your system however you desire. Will probably not clobber
  existing files, but it might ;)

  PLEASE SET GLOBAL VARIABLES in this script (#{File.basename(__FILE__)})!

  PREREQS:
  sudo apt-get install <prereq>
    make, g++, ruby, apache2, libzzip-dev, libgd2-dev, libpng3-dev libexpat-dev 
  --> or all on one line:
  sudo apt-get install make g++ ruby apache2 libzzip-dev libgd2-dev libpng3-dev libexpat-dev

  In all likelihood, this will need to be run as root.
  "
  exit
end

#########################
# MAKE INSTALLATION DIR:
#########################
mkpath HARD_CODED_TPP_INSTALL_STUB  # dir to hold soft link
mkpath TPP_INSTALL
soft_link(TPP_INSTALL, HARD_CODED_TPP_INSTALL.sub(/\/$/,''))

############################
# MAKE WEB DIRS:
############################
mkpath TPP_WEB_PATH_STUB
soft_link(TPP_DATA_PATH, TPP_DATA_PATH_SOFT_LINK)

mkpath TPP_DATA_PATH.chomp('/')
chmod(0777, TPP_DATA_PATH.chomp('/'))
mkpath TPP_VIS_PATH.chomp('/')

## VERY SPECIFIC to OUR SYSTEM
soft_link('/project/marcotte/marcotte/ms', TPP_DATA_PATH.chomp('/') + '/ms')
system "sudo chown john:marcotte #{TPP_DATA_PATH.chomp('/')}"
system "sudo chown john:marcotte #{TPP_VIS_PATH.chomp('/')}"

############################
# FIX UP APACHE
############################
modify_and_restart_apache(TPP_ROOT, WEBSERVER_ROOT, TPP_VIS_PATH,  MODS_AVAILABLE, MODS_ENABLED)

############################
# MAKE and INSTALL
############################
Dir.chdir ARGV[0] do
  ############################
  # SWAP OUT BAD LINES
  ############################
  swap_line(makefile_incl, /TPP_ROOT=.*/, 'TPP_ROOT='+TPP_ROOT)
  swap_line(makefile_incl, /TPP_WEB=.*/, 'TPP_WEB='+TPP_WEB)
  swap_line(sequest2xml, /if\(k < 12\) \{/, 'if(k < 6) {' )
  swap_line(sequest2xml, /cerr << " error: length of " << result->spectrum_ << " less than 13" << endl;/, 'cerr << " error: length of " << result->spectrum_ << " less than 6" << endl;')
  # CLEAN, MAKE, MAKE INSTALL:
  Dir.chdir('src') do
    sys "make clean"
    sys "make all"
    sys "make install"
  end
end

############################
# CREATE ADDITIONAL LINKS:
############################
soft_link(NICE_PATH, '/bin/nice')
soft_link(TPP_ROOT + 'bin/xinteract', BIN_DIR + XINTERACT_ISB)
puts "LINKING batchcoverage to #{BIN_DIR}batchcoverage"
soft_link(TPP_ROOT + 'bin/batchcoverage', BIN_DIR + 'batchcoverage')
soft_link(TPP_ROOT + 'bin/Sequest2XML', BIN_DIR + 'Sequest2XML')

############################
# CREATE xinteract wrapper:
############################
puts "CREATING xinteract wrapper script '#{BIN_DIR}#{XINTERACT_WRAPPER}'"
File.open("#{BIN_DIR}#{XINTERACT_WRAPPER}", "w") do |fh| fh.print(xinteract_wrapper) end
puts `chmod +x #{BIN_DIR}#{XINTERACT_WRAPPER}`


