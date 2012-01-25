require 'set'
require 'merge'
require 'nokogiri'

module MS ; end
module MS::Ident ; end


class MS::Ident::Pepxml 

  class MS::Ident::Pepxml::SearchHit 
    include Merge

    DEFAULT_MEMBERS = [:hit_rank, :peptide, :peptide_prev_aa, :peptide_next_aa, :num_matched_ions, :tot_num_ions, :calc_neutral_pep_mass, :massdiff, :num_tol_term, :num_missed_cleavages, :is_rejected, :protein, :num_tot_proteins, :protein_desc, :calc_pI, :protein_mw, :modification_info, :search_scores, :spectrum_query]

    Required = Set.new([:hit_rank, :peptide, :protein, :num_tot_proteins, :calc_neutral_pep_mass, :massdiff])

    class << self
      attr_writer :members
      def members
        @members || DEFAULT_MEMBERS
      end
    end

    members.each {|memb| attr_accessor memb }

    # rank of the peptide hit (required)
    attr_accessor :hit_rank
    # Peptide aminoacid sequence (with no indicated modifications) (required)
    attr_accessor :peptide

    # Aminoacid preceding peptide ('-' if none)
    attr_accessor :peptide_prev_aa

    # Aminoacid following peptide (- if none)
    attr_accessor :peptide_next_aa

    # Number of peptide fragment ions found in spectrum (Integer)
    attr_accessor :num_matched_ions

    # Number of peptide fragment ions predicted for peptide (Integer)
    attr_accessor :tot_num_ions

    # (required)
    attr_accessor :calc_neutral_pep_mass

    # Mass(precursor ion) - Mass(peptide) (required)
    attr_accessor :massdiff

    # Number of peptide termini consistent with cleavage by sample enzyme
    attr_accessor :num_tol_term

    # Number of sample enzyme cleavage sites internal to peptide<
    attr_accessor :num_missed_cleavages

    # Potential use in future for user manual validation (true/false)
    # by default, this will be set to false
    # (the xml is expressed as a 0 or 1)
    attr_accessor :is_rejected

    # a protein identifier string (required)
    attr_accessor :protein

    # Number of unique proteins in search database containing peptide
    # (required)
    attr_accessor :num_tot_proteins

    # Extracted from search database
    attr_accessor :protein_desc

    attr_accessor :calc_pI
    attr_accessor :protein_mw

    # a ModificationInfo object
    attr_accessor :modification_info

    # a Hash with keys (the score type) and values
    # (to_xml calls each_pair to generate the xml, so a Struct would also
    # work)
    attr_accessor :search_scores

    # a link back to the spectrum_query object
    attr_accessor :spectrum_query


    Non_standard_amino_acid_char_re = %r{[^A-Z\.\-]}

    alias_method :aaseq, :peptide
    alias_method :aaseq=, :peptide=

    # takes either a hash or an ordered list of values to set.
    # yeilds an empty search_scores hash if given a block.
    # mind that you set the ModificationInfo object as needed.
    def initialize(*args, &block)
      @search_scores = {}
      if args.first.is_a?(Hash)
        merge!(args.first)
      else
        self.class.members.zip(args) do |k,v|
          send("#{k}=", v)
        end
      end
      block.call(@search_scores) if block
    end

    def members
      self.class.members
    end

    def to_xml(builder=nil)
      xmlb = builder || Nokogiri::XML::Builder.new
      attrs = members[0,14].map {|k| v=send(k) ; [k, v] if v }.compact
      hash_attrs = Hash[attrs]
      hash_attrs[:massdiff] = hash_attrs[:massdiff].to_plus_minus_string
      xmlb.search_hit(hash_attrs) do |xmlb|
        @modification_info.to_xml(xmlb) if @modification_info
        @search_scores.each_pair {|k,v| xmlb.search_score(:name => k, :value => v) }
      end
      builder || xmlb.doc.root.to_xml
    end

    def from_pepxml_node(node)
      node.attributes
      self[0] = node['hit_rank'].to_i
      self[1] = node['peptide']
      self[2] = node['peptide_prev_aa']
      self[3] = node['peptide_next_aa']
      self[4] = node['protein']  ## will this be the string?? (yes, for now)
      self[5] = node['num_tot_proteins'].to_i
      self[6] = node['num_matched_ions'].to_i
      self[7] = node['tot_num_ions'].to_i
      self[8] = node['calc_neutral_pep_mass'].to_f
      self[9] = node['massdiff'].to_f
      self[10] = node['num_tol_term'].to_i
      self[11] = node['num_missed_cleavages'].to_i
      self[12] = node['is_rejected'].to_i
      self
    end

    Simple = Struct.new(:id, :search, :aaseq, :charge, :search_scores)
  end

end

