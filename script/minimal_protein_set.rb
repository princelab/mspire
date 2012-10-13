#!/usr/bin/ruby

require 'yaml'
require 'set'
require 'optparse'
require 'mspire/fasta'
require 'mspire/ident/peptide/db/io'

SET_RE = /Set\s+(.*)/i
QVALUE_EXT = ".phq.tsv"

# returns [sets_to_paths_hash, sets_order]
  def sets_compare_to_paths(file, ext=QVALUE_EXT)
  dirname = File.dirname(File.expand_path(file))
  lines = IO.readlines(file).map {|v| v.chomp }.select {|v| v =~ /\w/}
  sets = {}
  current_set = nil
  sets_order = []
  lines.each do |line|
    if line =~ SET_RE
      current_set = $1.dup
      sets[current_set] = [] 
      sets_order << current_set
    else
      full_path = (File.join(dirname,(line + ext)))
      raise RuntimeError, "file #{full_path} does not exist!!" unless File.exist?(full_path)
      sets[current_set] << full_path
    end
  end
  [sets, sets_order]
end

# returns [minimal_protein_to_uniq_peps_hash, indistinguishable_protein_hash] 
# takes a hash of proteins to aaseqs. Uses a greedy algorithm where
# things are sorted first by the number of uniq amino acid sequences and total
# aa length.  if a block is given, then will yield the prot and the
# peptide_array and sort by the returned value.  The greedy algorithm acts on
# the REVERSE of the sorted proteins.  indistinguishable_protein_hash is keyed
# on the proteins in the minimal_protein_array and gives an array of other
# proteins.  
def minimal_protein_set(proteins_to_aaseqs)
  blk_given = block_given?
  #STDERR.puts "using block for minimal_protein_set" if blk_given
  proteins_and_uniq_peps = []

  sorted_most_to_least = proteins_to_aaseqs.sort_by do |k,v| 
    if blk_given
      yield(k,v)
    else
      [ v.size, v.inject(0){|m,s| m+s.size} ]
    end
  end.reverse

  found_seq = Set.new

  same_peptide_hits = {}

  last_peps = nil
  last_uniq_prot = nil
  sorted_most_to_least.each do |prot, peps|
    sorted_peps = peps.sort # is it necessary to SORT?????????
    uniq_peps = peps.select do |pep|
      if found_seq.include?(pep)
        false
      else
        found_seq.add pep
        true
      end
    end
    if uniq_peps.size > 0
      proteins_and_uniq_peps << [prot, uniq_peps]
      same_peptide_hits[prot] = []
      last_peps = sorted_peps
      last_uniq_prot = prot
    else
      if sorted_peps == last_peps 
        same_peptide_hits[last_uniq_prot] << prot
      end
    end
  end
  prot_to_uniq_peps_hash = {}
  proteins_and_uniq_peps.each do |prot, uniq_peps|
    prot_to_uniq_peps_hash[prot] = uniq_peps
  end

  [prot_to_uniq_peps_hash, same_peptide_hits]
end

def cutoffs_to_floats(ar)
  ar.map do |v|
    if v == 'nil' || v == '-'
      nil
    else
      answ = v.to_f
    end
  end
end

# returns a hash keyed on protein id that yields an array:
#   [#aaseq, #aaseq_and_charge, #total_hits]
def stats_per_prot(prot_to_peps, seq_to_hits)
  per_protein_hash = {}
  prot_to_peps.each do |prot, uniq_pep_seqs|
    all = Set.new
    aaseqcharges = Set.new
    aaseqs = Set.new

    uniq_pep_seqs.each do |pep_seq|
      all_hits = seq_to_hits[pep_seq]
      all.merge( all_hits )
      all_hits.each do |hit|
        aaseq = hit.sequence
        aaseqs.add( aaseq )
        aaseqcharges.add( aaseq + '_' + hit.charge.to_s )
      end
      per_protein_hash[prot] = [aaseqs.size, aaseqcharges.size, all.size]

    end
  end
  per_protein_hash
end

opt = {
  :cutoffs => [nil],
  :outfile => "summary.yml",
}

opts = OptionParser.new do |op|
  op.banner = "usage: #{File.basename(__FILE__)} pepcentric_db.yml sets_compare.txt"
  op.separator "output: #{opt[:outfile]}"
  op.separator ""
  op.separator "input: "
  op.separator "    each <file> referenced in sets_compare.txt should have a"
  op.separator "    <file>.phq.tsv file"
  op.separator ""
  op.separator "options:"
  op.on("-q", "--qvalue <0-1[,...]>", Array, "only take qvalues < given ['-' for no threshold]") {|v| opt[:cutoffs] = cutoffs_to_floats(v)}
  op.separator ""
  op.separator "formats:"
  op.on("--output-format", "prints the output yaml scheme and exits") {|v| opt[:output_format] = v }
  op.on("--input-format", "prints sets_compare.txt format and exits") {|v| opt[:input_format] = v }
  op.on("--pepcentric-db-format", "prints peptide centric db format and exits") {|v| opt[:pepcentric_db_format] = v }
end

# later on we could implement full isoform resolution like IsoformResolver
# for now we will generate a report, realizing that some isoforms may not be
# reported
# it is implemented by using a pre-made map from sequence to protein groups
# then, a set of sequences allows one to deduce all the relationships from the 
# protein groups.

opts.parse!

pd = Mspire::Ident::Peptide::Db::PROTEIN_DELIMITER
kvd  = Mspire::Ident::Peptide::Db::KEY_VALUE_DELIMITER

if opt[:pepcentric_db_format]
  puts "pepcentric_db.yml needs to be in the format:"
  puts "<PEPTIDE>#{kvd.inspect}<ID>#{pd.inspect}<ID>#{pd.inspect}<ID>"
  puts "(The delimiters are shown with #inspect)"
end

if opt[:output_format]
  yaml = <<SKEL
results: 
- qvalue_cutoff: <Float>
  sets: 
    <set_name>: 
      num_uniq_aaseqs: <Integer>
      num_aaseqs_not_in_pep_db: <Integer>
      num_uniq_aaseqs_charge: <Integer>
      proteins: 
        <protein_id>: 
          num_hits_all: 
          - <Integer> # total num aaseqs
          - <Integer> # total num aaseq+charge "prints sets_compare.txt format and exits") {|v| opt[:input_format] = v }
  op.on("--pepcentric-db-
          - <Integer> # total num hits
          num_hits_minimal: 
          - <Integer> # total num aaseqs
          - <Integer> # total num aaseq+charge
          - <Integer> # total num hits
          indistinguishable: 
          - <protein_id>
          - <protein_id>
          aaseqs: 
          - <String>
          - <String>
sets_order:
- <String>
- <String>
SKEL
  print yaml
end

if opt[:input_format]
  string =<<EXPLANATION
# the sets_compare.txt format is very simple:

Set <some_name_for_set1>
filename1_no_ext
filename2_no_ext
Set <some_name_for_set2>
filename3_no_ext
filename4_no_ext
...
EXPLANATION
  puts string
end

exit if opt.keys.any? {|key| key.to_s =~ /_format/ }

if ARGV.size != 2
  p opts
  puts opts.to_s
  exit
end

(pepcentric_fn, sets_compare_fn) = ARGV

results = {}

results['results'] = []

(sets_hash, sets_order) = sets_compare_to_paths(sets_compare_fn)
results['sets_order'] = sets_order

STDERR.print "Loading peptide centric DB (this takes about a minute)..."
start = Time.now
Mspire::Ident::Peptide::Db::IO.open(pepcentric_fn) do |pep_to_prots|
  STDERR.puts "#{Time.now - start} seconds."

  opt[:cutoffs].each do |cutoff|

    cutoff_results = {'qvalue_cutoff' => cutoff}
    results_sets_hash = {}
    cutoff_results['sets'] = results_sets_hash
    results['results'] << cutoff_results

    #########################
    # FOR EACH SET:
    #########################
    pep_klass = nil
    sets_hash.each do |set, files|
      set_results = {}
      results_sets_hash[set] = set_results

      # assumes the indices are the same into each data file

      # get the complete set of passing hits
      all_passing_hits = files.inject([]) do |all_passing_hits, file|
        hash = YAML.load_file(file)

        header_hash = hash['headers']
        pep_klass ||= Struct.new(*(header_hash.map {|v| v.to_sym }))
        hits = hash['data'].map {|v| pep_klass.new(*v) }

        passing_hits = 
          if cutoff
            # assumes monotonic qvalues values!
            (above, below) = hits.partition {|hit| hit.qvalue <= cutoff }
            above
          else
            hits
          end
        all_passing_hits.push(*passing_hits)
      end


      # create an index from aaseq to hits
      seq_to_hits = Hash.new {|h,k| h[k] = []}
      uniq_seqcharge = Set.new
      all_passing_hits.each do |hit|
        seq_to_hits[hit.sequence] << hit
        uniq_seqcharge.add( hit.sequence + '_' + hit.charge.to_s )
      end


      # determine the number of uniq aaseqs
      uniq_seqs = seq_to_hits.size

      num_uniq_seqcharges = uniq_seqcharge.size

      set_results.merge!( { 'num_peptide_hits' => all_passing_hits.size,
                         'num_uniq_aaseqs' => uniq_seqs,
                         'num_uniq_aaseqs_charge' => num_uniq_seqcharges,
      })

      # create an index from proteins to peptides
      prots_to_peps = Hash.new {|h,k| h[k] = [] }
      peptides_not_found = []
      seq_to_hits.keys.each do |seq|
        if pep_db.key?(seq)
          pep_db[seq].each do |prot|
            prots_to_peps[prot] << seq
          end
        else
          peptides_not_found << seq
        end
      end

      # Determine the number of 1) hits, 2) aaseqs, 3) aaseqcharges per protein BEFORE minimization
      stats_per_protein_before = stats_per_prot(prots_to_peps, seq_to_hits)

      # get the minimal protein set
      (prot_to_uniq_peps_hash, indistinguishable_protein_hash) = minimal_protein_set(prots_to_peps) do |prot,peps|
        # will sort with lowest 
        [ peps.size, peps.inject(0){|m,s| m+s.size}, -(prot_sizes_hash[prot])]
      end

      prot_to_uniq_peps_hash.each do |prot, peps|
        [prot, *indistinguishable_protein_hash[prot]].each do |prot|
          protein_info[prot] = prot_header_hash[prot]
        end
      end

      stats_per_protein_minimal = stats_per_prot(prot_to_uniq_peps_hash, seq_to_hits)

      # create a hash of data for each protein
      protein_data_hashes_hash = {}
      prot_to_uniq_peps_hash.each do |prot, peps|
        protein_data_hashes_hash[prot] = { 
          'aaseqs' => peps,
          # this will be a triplet 
          'num_hits_minimal' => stats_per_protein_minimal[prot],
          'indistinguishable' => indistinguishable_protein_hash[prot],
          'num_hits_all' => stats_per_protein_before[prot],
        } 
      end

      set_results['proteins'] = protein_data_hashes_hash
      set_results['num_proteins'] = prot_to_uniq_peps_hash.size
      set_results['num_aaseqs_not_in_pep_db'] = peptides_not_found.size
      if peptides_not_found.size > 0
        warn "Did not find in peptide centric db: #{peptides_not_found.join(', ')}"
      end
    end
  end

  File.open(opt[:outfile], 'w') do |out|
    out.print results.to_yaml
  end

end

