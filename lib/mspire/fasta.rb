require 'bio'
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

    # returns two hashes [id_to_length, id_to_description]
    # faster (~4x) than official route.
    def self.protein_lengths_and_descriptions(file)
      protid_to_description = {}
      protid_to_length = {}
      re = /^>([^\s]+) (.*)/
        ids = []
      lengths = []
      current_length = nil
      IO.foreach(file) do |line|
        line.chomp!
        if md=re.match(line)  
          lengths << current_length
          current_id = md[1]
          ids << current_id
          current_length = 0
          protid_to_description[current_id] = md[2]
        else
          current_length += line.size
        end
      end
      lengths << current_length
      lengths.shift # remove the first nil entry
      [Hash[ids.zip(lengths).to_a], protid_to_description]
    end

  end
end
