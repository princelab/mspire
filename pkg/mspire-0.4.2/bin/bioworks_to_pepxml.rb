#!/usr/bin/ruby -w

##############################################################
# GLOBAL CONSTANTS

DEFAULT_DATABASE_PATH = "/project/marcotte/marcotte/ms/database"
DEFAULT_MZ_PATH = "."
DEFAULT_OUTDIR = "pepxml"
DEFAULT_PARAMS_GLOB = "*.params"
DEFAULT_PARAMS_FILE = Dir[DEFAULT_PARAMS_GLOB].first
DEFAULT_MS_MODEL = 'LCQ'
DEFAULT_MASS_ANALYZER = 'Ion Trap'
##############################################################

#require 'spec_id/sequest/pepxml'  # dies of this guy is called (why???)
require 'spec_id/proph/pep_summary'  # <- he requests the above...hmmm
require 'spec_id'
require 'optparse'
require 'ostruct'
require 'fileutils'
require 'spec_id/srf'

# establish the default database path after examining env vars
def_dbpath = nil
db_env_var = ENV["BIOWORKS_DBPATH"]
if db_env_var
  def_dbpath = db_env_var
else
  def_dbpath = DEFAULT_DATABASE_PATH
end

opt = OpenStruct.new

opt_obj = OptionParser.new do |op|
  progname = File.basename(__FILE__)
  op.banner = "\nusage: #{progname} [options] <file>.srf ..."
  op.separator "usage: #{progname} [options] <bioworks>.srg"
  op.separator "usage: #{progname} [options] <bioworks>.xml"
  op.separator ""
  op.separator "Takes srf files or the xml exported output of Bioworks multi-consensus view"
  op.separator "(no filtering) and outputs pepXML files (to feed the trans-proteomic pipeline)."
  op.separator "Additionally, will group .srf files into an .srg file (like 'srf_group.rb')"
  op.separator ""
  op.separator "Options:"
  op.on('-h', '--help', "display this and more notes and exit") {|v| opt.help = v }
  op.on('-o', '--outdir path', "output directory     d: '#{DEFAULT_OUTDIR}'") {|v| opt.outdir = v }
  op.on('--sample_enzyme <type>', "For digested samples run with no enzymatic",
                                  "search constraint, the enzyme used for",
                                  "digestion, options: 'Trypsin_KR_P'") {|v| 
    case v
    when 'Trypsin_KR_P'
      opt.sample_enzyme = SampleEnzyme.new("trypsin")
    else
      raise ArgumentError, "Don't recognize enzyme: #{v}"
    end
  } 
  op.on('-a', '--all_hits', "includes all hits, not just top xcorr") {|v| opt.all_hits = v }
  op.on('--deltacn_orig', "top hit deltacn = 0.0, (no deltacnstar att)") {|v| opt.deltacn_orig = v }
  op.on('-m', '--mspath path', "path to MS files     d: '#{DEFAULT_MZ_PATH}'") {|v| opt.mspath = v }
  op.on('--copy_mzxml', "copies mzXML files to outdir path"){|v| opt.copy_mzxml = v }

  op.separator ""
  op.separator "bioworks.xml files may require additional options:"
  op.separator ""
  op.on('-p', '--params file', "sequest params file  d: '#{DEFAULT_PARAMS_FILE}'") {|v| opt.params = v }
  op.on('-d', '--dbpath path', "path to databases    d: '#{DEFAULT_DATABASE_PATH}'") {|v| opt.dbpath = v }
  op.on('--model <LCQ|Orbi|string>', "MS model      (xml)  d: '#{DEFAULT_MS_MODEL}'") {|v| opt.model = v }
  op.on('--mass_analyzer <string>',  "Mass Analyzer (xml)  d: '#{DEFAULT_MASS_ANALYZER}'") {|v| opt.mass_analyzer = v }

end

more_notes = "
Notes:

  mspath: Directory to RAW or mzXML files.
          This option is needed to view Pep3D files 
          and is critical with Bioworks 3.2 xml export files
  outdir: Path will be created if it does not already exist.
  (xml) : only bioworks.xml files need to include this information
  model : LCQ -> 'LCQ Deca XP Plus'
        : Orbi -> 'LTQ Orbitrap'
        : other string -> That's the string that will be used.

  options with spaces should be quoted: e.g., \"Time of Flight\"

Database Path:

  If the database path in the sequest.params file is valid, that will be used.
  Otherwise, will try (in order):
      1. --dbpath or -d option
      1. environmental variable BIOWORKS_DBPATH (currently: '#{db_env_var}')
      2. constant at top of this script         (currently: '#{DEFAULT_DATABASE_PATH}')
  "



opt_obj.parse!

# intercept before argv count
if opt.help
  puts opt_obj
  puts more_notes
  exit
end

if ARGV.size < 1
  puts opt_obj 
  exit
end



opt.outdir ||= DEFAULT_OUTDIR


files = ARGV.to_a
bioworks_file = files[0]
if files[0] =~ /\.srf/i
  srg_file = 'bioworks.srg'
  if File.exist? srg_file
    srg_file = 'bioworks.tmp.srg'
  end
  srg = SRFGroup.new(files)
  srg.to_srg(srg_file)
unless File.exist? srg_file
  abort "couldn't create #{srg_file} from: #{files.join(', ')}" 
end
bioworks_file = srg_file
end


case opt.model
when "LCQ"
  model = 'LCQ Deca XP Plus'
when "Orbi"
  model = 'LTQ Orbitrap'
else
  model = opt.model
end

opt.dbpath ||= def_dbpath
opt.mspath ||= DEFAULT_MZ_PATH
opt.params ||= DEFAULT_PARAMS_FILE
opt.mass_analyzer ||= DEFAULT_MASS_ANALYZER
opt.model ||= DEFAULT_MS_MODEL

xml_objs = Sequest::PepXML.set_from_bioworks(bioworks_file, {:params => opt.params, :ms_data => opt.mspath, :out_path => opt.outdir, :model => model, :backup_db_path => opt.dbpath, :copy_mzxml => opt.copy_mzxml, :ms_mass_analyzer => opt.mass_analyzer, :print => true, :all_hits => opt.all_hits, :deltacn_orig => opt.deltacn_orig, :sample_enzyme => opt.sample_enzyme})

