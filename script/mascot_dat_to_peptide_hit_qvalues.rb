#!/usr/bin/env ruby

require 'trollop'
require 'set'
require 'mspire/ident/peptide_hit/qvalue'
require 'mspire/error_rate/qvalue'
require 'mspire/mascot/dat'

# target-decoy bundle
SearchBundle = Struct.new(:target, :decoy) do
  # combines all bundles under self so that all targets are grouped and all
  # decoys are grouped.  returns self
  def combine(bundles)
    (targets, decoys) = bundles.map {|bundle| [bundle.target, bundle.decoy] }
    .transpose.map {|ars| ars.reduce(:+) }
    self
  end
end

PSM = Struct.new(:search_id, :id, :aaseq, :charge, :score)

# turns 1+ into 1
def charge_string_to_charge(st)
  md = st.match(/(\d)([\+\-])/)
  i = md[1].to_i 
  i *= -1 if (md[2] == '-')
  i
end

def run_name_from_dat(dat_file)
  filename =nil
  IO.foreach(dat_file) do |line| 
    if line =~ /^FILE=(.*?).mgf/i
      filename = $1.dup
      break
    end
  end
  filename
end

def read_mascot_dat_hits(dat_file)
  filename = run_name_from_dat(dat_file)

  reply = Mspire::Mascot::Dat.open(dat_file) do |dat|
    target_and_decoy = [true, false].map do |target_or_decoy|
      dat.each_peptide(target_or_decoy, 1).map do |pephit|
        query = dat.query(pephit.query_num)
        PSM.new(filename, query.title, pephit.seq, query.charge, pephit.ions_score) if pephit.ions_score
      end
    end
    SearchBundle.new(*target_and_decoy)
  end
end


def putsv(*args)
  puts(*args) if $VERBOSE
  $stdout.flush
end

combine_base  = "combined"

EXT = Mspire::Ident::PeptideHit::Qvalue::FILE_EXTENSION

opts = Trollop::Parser.new do
  banner %Q{usage: #{File.basename(__FILE__)} <mascot>.dat ...
outputs: <mascot>#{EXT}

    assumes a decoy search was run *with* the initial search
    phq.tsv?: see schema/peptide_hit_qvalues.phq.tsv
}
  text ""
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
  bundle = SearchBundle.new.combine(bundles)
  to_run[combine_base] = bundle
else
  files.zip(bundles) do |file, bundle|
    to_run[file.chomp(File.extname(file))] = bundle
  end
end

to_run.each do |file_base, bundle|
  putsv "calculating qvalues for #{file_base}"
  hit_and_qvalue_pairs = Mspire::ErrorRate::Qvalue.target_decoy_qvalues(bundle.target, bundle.decoy, :z_together => opt[:z_together])

  outfile = Mspire::Ident::PeptideHit::Qvalue.to_phq(file_base, *hit_and_qvalue_pairs.transpose)

  putsv "created: #{outfile}"
end

