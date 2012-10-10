require 'yaml'

module Mspire ; end
module Mspire::Ident ; end
module Mspire::Ident::Peptide ; end

# Very simple object for protein retrieval from a peptide-centric database
# See Mspire::Ident::Peptide::Db::IO for an on-disc version for larger files.
class Mspire::Ident::Peptide::Db
  PROTEIN_DELIMITER = "\t"
  KEY_VALUE_DELIMITER = ': '

  attr_accessor :data

  def initialize(db_file)
    @data = YAML.load_file(db_file)
  end

  # returns protein id's as an array
  def [](key)
    val=@data[key]
    val.chomp.split(PROTEIN_DELIMITER) if val
  end

  def keys
    @data.keys
  end

  def values
    @data.values
  end

  def size
    @data.size
  end
end
