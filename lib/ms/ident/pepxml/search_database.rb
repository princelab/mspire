require 'ms/fasta'
require 'merge'
module MS ; end
module MS::Ident ; end

class MS::Ident::Pepxml
  class SearchDatabase
    include Merge
    # required! the local, full path to the protein sequence database
    attr_accessor :local_path
    # required! 'AA' or 'NA'
    attr_accessor :seq_type

    # optional
    attr_accessor :database_name
    # optional
    attr_accessor :orig_database_url
    # optional
    attr_accessor :database_release_date
    # optional
    attr_accessor :database_release_identifier
    # optional
    attr_accessor :size_of_residues

    # takes a hash to fill in values
    def initialize(hash={}, get_size_of_residues=false)
      merge!(hash)
      if get_size_of_residues && File.exist?(@local_path)
        set_size_of_residues!
      end
    end

    # returns self for chaining
    def set_size_of_residues!
      @size_of_residues = 0
      MS::Fasta.foreach(@local_path) do |entry|
        @size_of_residues += entry.sequence.size
      end
      self
    end

    def to_xml(builder)
      attrs = [:local_path, :seq_type, :database_name, :orig_database_url, :database_release_date, :database_release_identifier, :size_of_residues].map {|k| v=send(k) ; [k, v] if v }.compact
      builder.search_database(Hash[attrs])
      builder
    end
  end

end
