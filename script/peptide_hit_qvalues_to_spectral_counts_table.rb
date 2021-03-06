#!/usr/bin/env ruby

require 'andand'
require 'set'
require 'ruport'

require 'mspire'
require 'mspire/ident/peptide_hit/qvalue'
require 'mspire/ident/peptide_hit'
require 'mspire/ident/protein_group'
require 'mspire/ident/protein'
require 'mspire/ident/peptide/db/io'
require 'mspire/quant/spectral_counts'
require 'mspire/quant/protein_group_comparison'
require 'mspire/quant/qspec/protein_group_comparison'
require 'mspire/quant/qspec'
require 'mspire/quant/cmdline'
require 'mspire/fasta'

require 'yaml'
require 'tempfile'

require 'trollop'

def putsv(*args)
  if $VERBOSE
    puts(*args) ; $stdout.flush
  end
end

def basename(file)
  base = file.chomp(File.extname(file))
  base=base.chomp(File.extname(base)) if File.extname(base) == '.phq'
  base
end

class Ruport::Data::Table
  # returns self
  def add_column_with_data(colname, array_of_data, opts={})
    self.add_column(colname, opts)
    self.data.zip(array_of_data) do |row, newval|
      row[colname] = newval
    end
    self
  end

  # acceptable opts:
  #
  #     :header => an array of lines (each which will be commented out)
  def to_tsv(file, opt={})
    delimiter = "\t" 
    File.open(file,'w') do |out|
      opt[:header].each {|line| out.puts "# #{line}" } if opt[:header]
      out.puts self.column_names.join(delimiter)
      self.sort_rows_by(:fdr).data.each do |row|
        out.puts row.to_a.join(delimiter)
      end
      opt[:footer].each {|line| out.puts "# #{line}" } if opt[:footer]
    end
  end

end

def write_subset(sample_to_pephits, outfile="peptidecentric_subset.yml")
  aaseqs_to_prots = {} 
  sample_to_pephits.map(&:last).flatten(1).each do |pephit|
    aaseqs_to_prots[pephit.aaseq] = pephit.proteins.map(&:id)
  end
  File.open(outfile,'w') do |out| 
    aaseqs_to_prots.each do |k,v| 
      out.puts(%Q{#{k}: #{v.join("\t") }}) 
    end
  end
end


outfile = "spectral_counts.tsv"
pephits_outfile = "spectral_counts.pephits.tsv"
delimiter = "\t"

opts = Trollop::Parser.new do
  banner %Q{usage: #{File.basename(__FILE__)} <fasta>.peptide_centric_db.yml group1=f1.phq.tsv,f2.phq.tsv group2=f3.phq.tsv,f4.phq.tsv
or (each file a group):    #{File.basename(__FILE__)} <fasta>.peptide_centric_db.yml file1.phq.tsv file2.phq.tsv ...

writes to #{outfile}
group names can be arbitrarily defined
}
  opt :fdr_percent, "%FDR as cutoff", :default => 1.0
  opt :qprot, "return qprot results (executes qprot-param or qprot-paired). Requires :fasta.  Only 2 groups currently allowed. Sorts table by FDR (ascending) then abs val of log_fold_change (descending).", :default => false
  opt :descriptions, "include descriptions of proteins, requires :fasta", :default => false
  opt :fasta, "the fasta file.  Required for :descriptions", :type => String
  opt :outfile, "the to which file data are written", :default => outfile
  opt :peptides, "also write peptide hits (to: #{pephits_outfile})", :default => false
  opt :verbose, "speak up", :default => false
  opt :count_type, "type of spectral counts (<spectral|aaseqcharge|aaseq>)", :default => 'spectral'
  opt :qprot_normalize, "normalize spectral counts per run", :default => false
  opt :qprot_keep_files, "keep a copy of the files submitted and returned from Qprot", :default => false
  opt :qprot_remove_sparse_rows, "remove any row with only one non-zero value", :default => false
  opt :version_tag, "pass in a version tag (e.g. pass in git describe --tags) for version record", :type => String
  opt :write_subset, "(dev use only) write subset db", :default => false
end

commandline_incantation = __FILE__ + " " + ARGV.join(" ")
opt = opts.parse(ARGV)
opt[:count_type] = opt[:count_type].to_sym
outfile = opt[:outfile] || outfile

$VERBOSE = opt.delete(:verbose)

if ARGV.size < 2
  opts.educate && exit
end

if opt[:descriptions] && !opt[:fasta]
  puts "You must provide a fasta file with --fasta to use descriptions!!"
  opts.educate && exit
end

peptide_centric_db_file = ARGV.shift
raise ArgumentError, "need .yml file for peptide centric db" unless File.extname(peptide_centric_db_file) == '.yml'
putsv "using: #{peptide_centric_db_file} as peptide centric db"

# groupname => files

(samplename_to_filename, condition_to_samplenames, samplename_to_condition) = Mspire::Quant::Cmdline.args_to_hashes(ARGV)

raise ArgumentError, "must have 2 conditions for qprot to work!" if opt[:qprot] && condition_to_samplenames.size != 2

samplenames = samplename_to_filename.keys

class Mspire::Ident::PeptideHit
  attr_accessor :experiment_name
  attr_accessor :protein_groups
end

#class Mspire::Ident::Protein
#  attr_accessor :length
#end


fdr_cutoff = opt[:fdr_percent] / 100

if opt[:descriptions]
  putsv "reading descriptions from #{opt[:fasta]}"
  #Mspire::Fasta.protein_lengths_and_descriptions(opt[:fasta])
  id_to_desc = {}
  Mspire::Fasta.foreach(opt[:fasta]) do |entry|
    #acc = Mspire::Fasta.uniprot_id(entry.header)
    acc = entry.accession
    id_to_desc[acc] = entry.definition[/^\S+\s(.*)/,1]
  end
end

samplename_to_peptidehits = samplename_to_filename.map do |sample, file|
 [sample, Mspire::Ident::PeptideHit::Qvalue.from_file(file).select {|hit| hit.qvalue <= fdr_cutoff }]
end

# update each peptide hit with protein hits and sample name:
all_protein_hits = Hash.new {|h,id| h[id] = Mspire::Ident::Protein.new(id) }

Mspire::Ident::Peptide::Db::IO.open(peptide_centric_db_file) do |peptide_to_proteins|
  samplename_to_peptidehits.map do |sample, peptide_hits|
    # removes pephits that aren't in the database, (usually ones with aa 'X'
    # in them )
    normal_pephits = peptide_hits.select {|hit| peptide_to_proteins[hit.aaseq] }
    normal_pephits.each do |hit|
      # update each peptide with its protein hits
      protein_hits = peptide_to_proteins[hit.aaseq].map do |id| 
        protein = all_protein_hits[id]
        protein.description = id_to_desc[id] if id_to_desc
        protein
      end
      hit.experiment_name = sample
      # if there are protein hits, the peptide hit is selected 
      hit.proteins = protein_hits
    end
  end
end

write_subset(samplename_to_peptidehits) if opt[:write_subset]

samplename_to_peptidehits.each {|samplename, hits| putsv "#{samplename}: #{hits.size}" } if $VERBOSE

all_peptide_hits = samplename_to_peptidehits.map(&:last).flatten(1)

# this constricts everything down to a minimal set of protein groups that
# explain the entire set of peptide hits.   
update_pephits = true  # ensures that each pephit is linked to the array of protein groups it is associated with
protein_groups = Mspire::Ident::ProteinGroup.peptide_hits_to_protein_groups(all_peptide_hits, update_pephits)

hits_table_hash = {}  # create the table using key => column hash
samplenames.each do |name|
  hits_table_hash[name] = protein_groups.map do |prot_group|
    prot_group.peptide_hits.select {|hit| hit.experiment_name == name }
  end
end

# The columns are filled with groups of peptide hits, one group of hits per
# protein group (protein group order is implicit).  The rows are sample names.
#
#  (implied) sample1   sample2   sample3   ...
#  (group1)  [hit,hit] [hit...]  [hit...]  ...
#  (group2)  [hit,hit] [hit...]  [hit...]  ...
#   ...         ...       ...       ...       ...
hits_table = Ruport::Data::Table.new(:data => hits_table_hash.values.transpose, :column_names => hits_table_hash.keys)

# spectral counts of type opt[:count_type]
counts_data = hits_table.data.map do |row|
  row.map do |pephits|
    Mspire::Quant::SpectralCounts.counts(pephits) {|pephit| 1.0 / pephit.protein_groups.size }.send(opt[:count_type])
  end
end

# each cell holds a SpectralCounts object, which hash 3 types of count data
counts_table = Ruport::Data::Table.new(:data => counts_data, :column_names => samplenames)

counts_table.add_columns( [:name, :ids, :description, :qprot_protname] )
counts_table.data.zip(protein_groups) do |row, pg|
  best_id = pg.first   # pg.sort_by {|prot| [prot.id, prot.length] }.first
  row.name = best_id.description.andand.match(/ GN=([^\s]+) ?/).andand[1] || best_id.id
  row.ids = pg.map(&:id).join(',')
  row.description = best_id.description
  row.qprot_protname = pg.map(&:id).join(":")
end

# return a list of ProteinGroupComparisons
if opt[:qprot]

  if opt[:qprot_remove_sparse_rows]
    newrows = counts_table.data.select do |row|
      row.to_a[0,samplenames.size].select {|v| v > 0 }.size >= 2
    end
    counts_table = Ruport::Data::Table.new(:data => newrows, :column_names => counts_table.column_names)
  end

  # prepare data for qprot
  condition_to_count_array = counts_table.column_names.select {|name| name.is_a?(String) }.map do |name| 
    [samplename_to_condition[name], counts_table.column(name)]
  end

  qprot_results = Mspire::Quant::Qspec.new(counts_table.column(:qprot_protname), condition_to_count_array).run(opt[:qprot_normalize], :keep => opt[:qprot_keep_files])
  
  cols_to_add = [:log_fold_change, :fdr, :fdr_up, :fdr_down]

  counts_table.add_columns cols_to_add
  counts_table.data.zip(qprot_results) do |row, qprot_result|
    cols_to_add.each do |cat| 
      row[cat] = qprot_result[cat]
    end
  end

  # sort table ascending FDR, then negative abs value of log fold change!
  counts_table.sort_rows_by!(nil) {|r| [r[:fdr], -(r[:log_fold_change]).abs] }
end

counts_table.remove_column(:qprot_protname) # keep outside qprot block for now

if opt[:peptides]
  hits_table.each do |record|
    record.each_with_index do |hits,i|
      new_cell = hits.group_by do |hit| 
        [hit.aaseq, hit.charge]
      end.map do |key, hits|
        [key.reverse.join("_"), hits.map(&:id).join(',')].join(":")
      end.join('; ')
      record[i] = new_cell
    end
  end
  hits_table.add_column_with_data(:name, counts_table.column(:name), :position=>0)
  hits_table.to_tsv(pephits_outfile, :footer => ["parallel to #{outfile}"])
end

intro = [
  "",
  "ruby: #{RUBY_VERSION}",
  "software: mspire #{Mspire::VERSION}", 
  "cite: #{Mspire::CITE}",
  "samples: #{samplename_to_filename}", 
"options: #{opt}", 
"commandline: #{commandline_incantation}"
]
intro.insert(3, "version_tag: #{opt[:version_tag]}") if opt[:version_tag]

counts_table.to_tsv(outfile, :footer => intro)
