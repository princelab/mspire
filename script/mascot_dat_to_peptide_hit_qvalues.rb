#!/usr/bin/env ruby

require 'trollop'
require 'set'
require 'mspire/ident/peptide_hit/qvalue'
require 'mspire/error_rate/qvalue'

begin
  require 'mascot/dat'
rescue LoadError
  puts "You need the mascot-dat gem for this to work!"
  puts "AND IT MUST BE THE PRINCELAB GITHUB FORK until changes get incorporated upstream!"
  puts ">     gem install mascot-dat"
  raise LoadError
end
raise "need princelab mascot-dat gem!" unless Mascot::DAT::VERSION == "0.3.1.1"

# target-decoy bundle
TDB = Struct.new(:target, :decoy)

PSM = Struct.new(:aaseq, :charge, :score, :qvalue) 

# turns 1+ into 1
def charge_string_to_charge(st)
  md = st.match(/(\d)([\+\-])/)
  i = md[1].to_i 
  i *= -1 if (md[2] == '-')
  i
end

def read_mascot_dat_hits(dat_file)
  dat = Mascot::DAT.open(dat_file)
  data = [:peptides, :decoy_peptides].each do |mthd|
    psms = []
    dat.send(mthd).each do |psm|
      next unless psm.query
      query = dat.query(psm.query)
      charge = charge_string_to_charge(query.charge)
      psms << PSM.new(psm.pep, charge, psm.score) if psm.score
    end
  end
  dat.close
  TDB.new(*data)
end


def putsv(*args)
  puts(*args) if $VERBOSE
  $stdout.flush
end

EXT = Mspire::Ident::PeptideHit::Qvalue::FILE_EXTENSION
combine_base  = "combined"

opts = Trollop::Parser.new do
  #banner %Q{usage: #{File.basename(__FILE__)} <target>.xml <decoy>.xml ...
  banner %Q{usage: #{File.basename(__FILE__)} <mascot>.dat ...
outputs: <mascot>.phq.tsv
assumes a decoy search was run *with* the initial search
phq.tsv?: see schema/peptide_hit_qvalues.phq.tsv
}
  opt :combine, "groups target and decoy hits together from all files, writing to #{combine_base}#{EXT}", :default => false
  opt :z_together, "do not group by charge state", :default => false
  opt :verbose, "be verbose", :default => false
end

opt = opts.parse(ARGV)
if ARGV.size == 0
  opts.educate
  exit 
end

$VERBOSE = opt.delete(:verbose)

files = ARGV.to_a

bundles = files.map do |file|
  # assumes the file has both target and decoy hits
  read_mascot_dat_hits(file)
end

to_run = {}
if opt[:combine]
  putsv "combining all target hits together and all decoy hits together"
  all_target = [] ; all_decoy = []
  bundles.each do |bundle| 
    all_target.push(*bundle.target) 
    all_decoy.push(*bundle.decoy)
  end
  bundle = TDB.new(all_target, all_decoy)
  to_run[combine_base + EXT] = bundle
else
  files.zip(bundles) do |file, bundle|
    to_run[file.chomp(File.extname(file)) + EXT] = bundle
  end
end

to_run.each do |file, bundle|
  putsv "calculating qvalues for #{file}"
  hit_qvalue_pairs = Mspire::ErrorRate::Qvalue.target_decoy_qvalues(bundle.target, bundle.decoy, :z_together => opt[:z_together])
  # {|hit| hit.search_scores[:ionscore] }
  hits = [] ; qvals = []
  hit_qvalue_pairs.each do |hit, qval|
    hits << hit ; qvals << qval
  end
  outfile = Mspire::Ident::PeptideHit::Qvalue.to_file(file, hits, qvals)
  putsv "created: #{outfile}"
end


