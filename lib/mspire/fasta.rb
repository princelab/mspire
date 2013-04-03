require 'bio/io/flatfile'
require 'bio/db/fasta'
require 'stringio'

class Bio::FlatFile
  include Enumerable
end

class Bio::FastaFormat
  alias_method :header, :definition
  alias_method :sequence, :seq
end

module Mspire
  # A convenience class for working with fasta formatted sequence databases.
  # the file which includes this class also includes Enumerable with
  # Bio::FlatFile so you can do things like this:
  #
  #     accessions = Mspire::Fasta.open("file.fasta") do |fasta| 
  #       fasta.map(&:accession)
  #     end
  # 
  # A few aliases are added to Bio::FastaFormat
  #
  #     entry.header == entry.definition
  #     entry.sequence == entry.seq
  #
  # Mspire::Fasta.new accepts both an IO object or a String (a fasta formatted
  # string itself)
  #
  #     # taking an io object:
  #     File.open("file.fasta") do |io| 
  #       fasta = Mspire::Fasta.new(io)
  #       ... do something with it
  #     end
  #     # taking a string
  #     string = ">id1 a simple header\nAAASDDEEEDDD\n>id2 header again\nPPPPPPWWWWWWTTTTYY\n"
  #     fasta = Mspire::Fasta.new(string)
  #     (simple, not_simple) = fasta.partition {|entry| entry.header =~ /simple/ }
  module Fasta

    # opens the flatfile and yields a Bio::FlatFile object
    def self.open(file, &block)
      Bio::FlatFile.open(Bio::FastaFormat, file, &block)
    end

    # yields each Bio::FastaFormat object in turn
    def self.foreach(file, &block)
      block or return enum_for(__method__, file)
      Bio::FlatFile.open(Bio::FastaFormat, file) do |fasta|
        fasta.each(&block)
      end
    end

    # takes an IO object or a string that is the fasta data itself
    def self.new(io)
      io = StringIO.new(io) if io.is_a?(String)
      Bio::FlatFile.new(Bio::FastaFormat, io)
    end

    # takes the header string and returns the uniprot id
    #
    #     'sp|Q04917|1433F_HUMAN' #=> 'Q04917'
    # This can also be found with BioFastaFormat#accession (but it may be much
    # slower)
    def self.uniprot_id(header)
      header[/^[^\|]+\|([^\|]+)\|/, 1]
    end
  end
end
