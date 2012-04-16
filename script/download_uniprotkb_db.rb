#!/usr/bin/env ruby

require 'optparse'
require 'open-uri'
require 'cgi'

# see http://www.uniprot.org/faq/28

# here are some example human files (tax ID = 9606)
# CANONICAL SEQUENCES:
# http://www.uniprot.org/uniprot/?query=taxonomy:9606&force=yes&format=fasta
#   URL SAFE: 
#   http://www.uniprot.org/uniprot/?query=taxonomy%3a9606&force=yes&format=fasta

# CANONICAL + VARIANTS:
# http://www.uniprot.org/uniprot/?query=taxonomy:9606&force=yes&format=fasta&include=yes
#   URL SAFE: http://www.uniprot.org/uniprot/?query=taxonomy%3a9606&force=yes&format=fasta&include=yes


FORMATS = %w(fasta gff xls tab txt xml rdf list)
# list is just a list of accession numbers

# include includes sequence variants (otherwise canonical)
args = { :format => FORMATS.first, :force => 'yes', :include => 'yes', :compress => 'yes' }
# force just makes the file a download (matters for browsers)

# queries are in this format:
# query=organism:9606+AND+organelle:mitochondrion

#[OC] taxonomy
#[OG] organelle

TAXONOMY_BROWSER_URL = "http://www.ncbi.nlm.nih.gov/Taxonomy/taxonomyhome.html/index.cgi"

=begin
Y is a mnemonic species identification code of at most 5 alphanumeric
characters representing the biological source of the protein. This
code is generally made of the first three letters of the genus and
the first two letters of the species. Examples: PSEPU is for
Pseudomonas putida and NAJNI is for Naja nivea.

However, for species commonly encountered in the data bank, self-
explanatory codes are used. There are 16 of those codes. They are:
BOVIN for Bovine, CHICK for Chicken, ECOLI for Escherichia coli,
HORSE for Horse, HUMAN for Human, MAIZE for Maize (Zea mays) , MOUSE
for Mouse, PEA for Garden pea (Pisum sativum), PIG for Pig, RABIT
for Rabbit, RAT for Rat, SHEEP for Sheep, SOYBN for Soybean (Glycine
max), TOBAC for Common tobacco (Nicotina tabacum), WHEAT for Wheat
(Triticum aestivum), YEAST for Baker's yeast (Saccharomyces
cerevisiae).

BOVIN
CHICK
ECOLI
HORSE
HUMAN
MAIZE
MOUSE
PEA
PIG
RABIT
RAT
SHEEP
SOYBN
TOBAC
WHEAT
YEAST

=end

TAXONOMY_IDS = 
  { :human => [9606, 'Homo sapiens'],
    :mouse => [10090, 'Mus musculus'],
    :yeast => [4932, 'Saccharomyces cerevisiae'],
    :ecoli => [562, 'Escherichia coli'],
    :caeel => [6239, 'Caenorhabditis elegans'],
    :drome => [7227, 'Drosophila melanogaster'],
    :grpln => [33090, 'Viridiplantae'],
  }

def list_taxonomies
  puts "  Key    ID     Genus/Species"
  puts "  =====  =====  ============="
  puts( TAXONOMY_IDS.map {|k,v| "  %s %6d  %s" % [k,*v] }.join("\n") )
  puts ""
  puts "See #{TAXONOMY_BROWSER_URL}"
  true
end

opts = OptionParser.new do |op|
  op.banner = "usage: #{File.basename(__FILE__)} <5-Letter-Species-Name|taxID>"
  op.separator ""
  op.separator "   requires 5-letter key (Swiss-Prot Mnemonic) (-l to see list)"
  op.separator "   (note that outside the core ~12, these are just made up)"
  op.separator "   or the actual NCBI taxonomy ID"
  op.separator "   [add your key to TAXONOMY_IDS if you want]"
  op.separator ""
  op.on("-l", "--list-species", "lists available species and exits") { list_taxonomies && exit }
  op.on("-c", "--canonical", "don't include sequence variants") { args[:include] = 'no' }
  op.on("--no-compress", "don't compress the file") { args[:compress] = 'no' }
  op.on("-f", "--format <string>", "Format type.  One of (1st is default):", "    #{FORMATS.join(' ')}") do |v| 
    raise ArgumentError, "format needs to be one of: #{FORMATS.join(' ')}" unless FORMATS.include?(v)
    args[:format] = v
  end
  op.on("-v", "--verbose", "talk about it") { $VERBOSE = true }
end

opts.parse!

if ARGV.size == 0
  puts opts
  exit
end

mnemonic = ARGV.shift
# use the taxonomy id if exists, otherwise use the tax ID itself
tax_id = 
  if val = TAXONOMY_IDS[mnemonic.to_sym]
    val.first
  else
    mnemonic
  end
args[:query] = "taxonomy:#{tax_id}"

base_url = "http://www.uniprot.org/uniprot/?"
query_string = args.map {|k,v| [k,CGI.escape(v)].join('=') }.join("&")

url = base_url + query_string

prefix = "uni"
variants = (args[:include] == 'yes') ? 'var' : 'can'
short_date = Time.now.strftime("%y%m%d")
decoytype = "fwd"
postfix = ".fasta"

filename = [prefix, mnemonic, variants, short_date, decoytype].join("_") << postfix
(filename << ".gz") if args[:compress] == 'yes'
puts "reading from url : #{url}"
puts "writing to file  : #{filename}"
File.open(filename,'w') do |out|
  open(url) do |io|
    out.print( io.read )
  end
end


