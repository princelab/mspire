require 'mspire/ident/peptide/db'

class Mspire::Ident::Peptide::Db::IO
  # an object for on disk retrieval of db entries
  # proteins are returned as an array.
  # behaves like a hash once it is opened.
  include Enumerable
  def self.open(filename, &block)
    raise ArgumentError unless block
    File.open(filename) do |io|
      block.call(self.new(io))
    end
  end

  attr_accessor :io
  attr_accessor :index

  def initialize(io)
    @io = io
    @index = {}
    re = /^(\w+)#{Regexp.escape(Mspire::Ident::Peptide::Db::KEY_VALUE_DELIMITER)}/
      prev_io_pos = io.pos
    triplets = io.each_line.map do |line|
      key = re.match(line)[1]
      [key, prev_io_pos + key.bytesize+Mspire::Ident::Peptide::Db::KEY_VALUE_DELIMITER.bytesize, prev_io_pos=io.pos]
    end
    triplets.each do |key, start, end_pos|
      @index[key] = [start, end_pos-start]
    end
  end

  # returns an array of proteins for the given key (peptide aaseq)
  def [](key)
    (start, length) = @index[key]
    return nil unless start
    @io.seek(start)
    string = @io.read(length)
    string.chomp!
    string.split(Mspire::Ident::Peptide::Db::PROTEIN_DELIMITER)
  end

  def key?(key)
    @index[key]
  end

  # number of entries
  def size ; @index.size end
  alias_method :length, :size

  def keys
    @index.keys
  end

  # all the protein lists
  def values
    keys.map {|key| self[key] }
  end

  # yields a pair of aaseq and protein array
  def each(&block)
    @index.each do |key, start_length|
      block.call([key, self[key]])
    end
  end
end

