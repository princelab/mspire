#!/usr/bin/env ruby

require 'trollop'
require 'set'
require 'mascot/dat'

def read_mascot_dat_hits(dat_file)
  dat = Mascot::DAT.open(dat_file)
  dat.peptides.each do |pep|
    p pep.score
  end
  dat.close
end

begin
  require 'mascot/dat'
rescue LoadError
  puts "You need the mascot-dat gem for this to work!"
  puts ">     gem install mascot-dat"
  raise LoadError
end
require 'mspire/ident/peptide_hit/qvalue'
require 'mspire/ident/pepxml'

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

# groups_of_search_hits is just a list of alternating target and decoy hits
groups_of_search_hits = []
files.map do |file|
  putsv "reading search hits from dat: #{file}"
  (target, decoy) = read_mascot_dat_hits(file)
  groups_of_search_hits << target << decoy
end

to_run = {}
if opt[:combine]
  putsv "combining all target hits together and all decoy hits together"
  all_target = [] ; all_decoy = []
  groups_of_search_hits.each_slice(2) do |target_hits,decoy_hits| 
    all_target.push(*target_hits) ; all_decoy.push(*decoy_hits)
  end
  to_run[combine_base + EXT] = [all_target, all_decoy]
else
  files.zip(groups_of_search_hits).each_slice(2) do |pair_of_file_and_hit_pairs|
    (tfile_hits, dfile_hits) = pair_of_file_and_hit_pairs
    file = tfile_hits.first
    to_run[file.chomp(File.extname(file)) + EXT] = [tfile_hits.last, dfile_hits.last]
  end
end

to_run.each do |file, target_decoy_pair|
  putsv "calculating qvalues for #{file}"
  hit_qvalue_pairs = Mspire::ErrorRate::Qvalue.target_decoy_qvalues(target_decoy_pair.first, target_decoy_pair.last, :z_together => opt[:z_together]) {|hit| hit.search_scores[:ionscore] }
  hits = [] ; qvals = []
  hit_qvalue_pairs.each do |hit, qval|
    hits << hit ; qvals << qval
  end
  outfile = Mspire::Ident::PeptideHit::Qvalue.to_file(file, hits, qvals)
  putsv "created: #{outfile}"
end


