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
  run_name_from_dat(dat_file)

  Mspire::Mascot::Dat.open(dat_file) do |dat|
    data = [true, false].map do |mthd|

      ################################################################
      ################################################################
      ################################################################
      ################################################################
      ################################################################
      # working here
      ################################################################
      psms = []
      dat.send(mthd).each do |psm|
        next unless psm.query
        query = dat.query(psm.query)
        charge = charge_string_to_charge(query.charge)
        psms << PSM.new(filename, query.title, psm.pep, charge, psm.score) if psm.score
      end
      psms
    end
    dat.close
    SearchBundle.new(*data)
  end
end


def putsv(*args)
  puts(*args) if $VERBOSE
  $stdout.flush
end

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
  bundle = SearchBundle.new.combine(bundles)
  to_run[combine_base] = bundle
else
  files.zip(bundles) do |file, bundle|
    to_run[file.chomp(File.extname(file))] = bundle
  end
end

to_run.each do |file_base, bundle|
  putsv "calculating qvalues for #{file_base}"
  qvalues = Mspire::ErrorRate::Qvalue.target_decoy_qvalues(bundle.target, bundle.decoy, :z_together => opt[:z_together])
  # {|hit| hit.search_scores[:ionscore] }
  #outfile = Mspire::Ident::PeptideHit::Qvalue.to_file(file, *hit_qvalue_pairs.transpose)
  outfile = Mspire::Ident::PeptideHit::Qvalue.to_phq(file_base, bundle.target, qvalues)

  putsv "created: #{outfile}"
end

