require 'rexml/document'
require 'hash_by'
require 'instance_var_set_from_hash'
require 'axml'
require 'spec_id'
require 'arrayclass'

require 'spec_id/parser/proph'


module SpecID ; end
module SpecID::Prot ; end
module SpecID::Pep ; end

module Proph

  class ProtSummary
    include SpecID

    # if you get this match it's a protein prophet file and the version is the
    # first match!
    Filetype_and_version_re_old = /ProteinProphet_v([\.\d]+)\.dtd/  # gives 1.9 or what else?
    Filetype_and_version_re_new = /protXML_v([\.\d]+)\.xsd/        # gives 4 right now
    # inherits prots and peps

    # the protein groups
    attr_accessor :prot_groups
    attr_accessor :version

    def hi_prob_best ; true end

    def get_version(file)
      answer = nil
      File.open(file) do |fh|
        5.times do
          line = fh.gets
          answer = 
            if line =~ Filetype_and_version_re_new
              $1.dup
            elsif line =~ Filetype_and_version_re_old
              $1.dup
            end
          break if answer
        end
      end
      raise(ArgumentError, "couldn't detect version in #{file}") unless answer
      answer
    end

    def initialize(file=nil)
      @prots = nil
      if file
        @version = get_version(file)
        #@prot_groups = ProtSummary::Parser.new.parse_file(file)
        SpecID::Parser::ProtProph.new(:spec_id).parse(file, :spec_id => self)
      end
    end

    # returns a set of unique proteins
    def unique_prots(prot_groups)
      all_prots = []
      prot_groups.each do |pg|
        pg.prots.each do |prt|
          all_prots << prt
        end
      end
      all_prots.hash_by(:protein_name).map{|name,prot_arr| prot_arr.first }
    end

  end

  class ProtSummary::Parser
    attr_accessor :prot_groups
    def initialize(file=nil, with_peps=false, tp='axml')
      if file
        @prot_groups = parse_file(file, with_peps, tp)
      end
    end

    # returns an array of protein_groups
    def parse_file(file, with_peps=false, tp='axml')
      File.open(file) do |fh|
        @prot_groups = _parse_for_prot_groups(fh, with_peps, tp)
      end
      @prot_groups
    end

    # returns an array of ProtGroup objects
    def _parse_for_prot_groups(stream, with_peps=false, tp='axml')
      prtgrps = []
      case tp
      when 'axml'
        root = AXML.parse(stream)
        root.protein_group.each do |protein_group|
          pg = ProtGroup.new(protein_group.attrs) do 
            protein_group.map do |protein|
              Prot.new(protein.attrs)
            end
          end
          prtgrps << pg 
        end
      end
      prtgrps
    end
  end   # ProtSummary::Parser


  class ProtGroup
    attr_accessor :group_number, :probability, :prots
    def initialize(args=nil)
      @prots = []
      if args
        instance_var_set_from_hash(args)
      end
      if block_given?
        @prots = yield
      end
    end
  end

end  # Proph



Proph::Prot = Arrayclass.new(%w(protein_name probability n_indistinguishable_proteins percent_coverage unique_stripped_peptides group_sibling_id total_number_peptides pct_spectrum_ids description peps))

# note that 'description' is found in the element 'annotation', attribute 'protein_description'
# NOTE!: unique_stripped peptides is an array rather than + joined string
class Proph::Prot 
  include SpecID::Prot

  # returns protein_name
  def name ; self[0] end
  def reference ; self[0] end
  def first_entry ; self[0] end  # the name is also the first_entry

end

#def to_s
#  '<Prot: protein_name=' + @protein_name + ' ' + 'probability=' + @probability.to_s + '>'
#end

# this is a pep from a -prot.xml file

Proph::Prot::Pep = Arrayclass.new(%w(peptide_sequence charge initial_probability nsp_adjusted_probability weight is_nondegenerate_evidence n_enzymatic_termini n_sibling_peptides n_sibling_peptides_bin n_instances is_contributing_evidence calc_neutral_pep_mass modification_info prots))

class Proph::Prot::Pep
  include SpecID::Pep

  alias_method :mod_info, :modification_info
  alias_method :mod_info=, :modification_info=

  def aaseq ; self[0] end
  def probability ; self[3] end

end # class Pep

=begin
  #attr_accessor :sequence, :probability, :filenames, :charge, :precursor_neutral_mass, :nsp_cutoff, :scans
  #attr_writer :arithmetic_avg_scan_by_parent_time

  #def initialize(args=nil)
  #  if args
  #    @sequence = args[:sequence]
  #    @probability = args[:probability]  ## nsp prob
  #    @filenames = args[:filenames]
  #    @charge = args[:charge]
  #    @nsp_cutoff = args[:nsp_cutoff]
  #    if args.key?(:scans)
  #      @scans = args[:scans]
  #    else
  #      @scans = []  ## this is set later if needed 
  #    end
  #  else
  #    @scans = []
  #  end
  #end

  # filter peptides based on the number of scans
  # if a peptide has more than max_dups scans, the peptide is tossed
  # note that multiple scans that were used as a single dtafile scan
  # will be counted as a single scan for these purposes!
  # (easy, since they are stored as a single item in the array of scans)
  def self.filter_by_max_dup_scans(max_dups=nil, peps=nil)
    if max_dups
      new_peps = []
      peps.each do |pep|
        unless pep.scans.size > max_dups
          new_peps << pep
        end
      end
      new_peps
    else
      peps.dup
    end
  end


  ## from the list of scans, creates a scan object whose time is the
  ## arithmetic mean of the parent scans (based on prec_inten) and whose
  ## prec_mz is the avg of all prec_mz's.  num is nil, charge is the first
  def arithmetic_avg_scan_by_parent_time
    unless @arithmetic_avg_scan_by_parent_time
      flat_scans = @scans.flatten

      # new_prec_mz
      prec_mz_sum = 0.0
      prec_inten_sum = 0.0
      times = []
      intens = []
      tot_inten = 0.0
      flat_scans.each do |c|
        prec_inten = c.prec_inten
        prec_inten_sum += prec_inten
        prec_mz_sum += c.prec_mz
        tot_inten += prec_inten
        times << c.parent.time
        intens << prec_inten
      end
      new_prec_mz = prec_mz_sum / flat_scans.size
      new_prec_inten = prec_inten_sum / flat_scans.size

      fraction_inten = []
      intens.each do |inten|
        fraction_inten.push( inten/tot_inten )
      end

      new_time = 0.0
      (0...times.size).each do |i|
        new_time += times[i] * fraction_inten[i]
      end

      @arithmetic_avg_scan_by_parent_time = MS::Scan.new( nil, @scans.first.ms_level, new_time, new_prec_mz, new_prec_inten ) 

    end
    @arithmetic_avg_scan_by_parent_time
  end 

  def to_s
    '<Pep seq=' + @sequence + ' ' + 'prob=' + @probability.to_s + ' charge=' + @charge + '>'
  end

  def has_dta?(dta_filename)
    if @filenames
      @filenames.each do |fn|
        if dta_filename == fn
          return true
        end
      end
    end
    return false
  end


  # Given a list of peptides, returns only those unique based on
  # sequence/charge
  def self.uniq_by_seqcharge(peptides)
    # @TODO: this could be done with one fewer traversals, but it is beautiful
    peptides.hash_by(:sequence, :charge).collect do |k,v|
      v.first 
    end
  end
=end





=begin

# Class for parsing the peptide prophet output files in various ways
class Proph::Pep::Parser < Parser

  # parse_type = "rexml" | "regex"
  # regex's are about 50 times faster but are not guaranteed to work
  # seq charge hash is keyed on an array -> [sequence,charge]
  # @TODO: implement parsing on this with xmlparser
  def dta_filenames_by_seq_charge(pep_xml_file, parse_type="rexml")
    seq_charge_hash = Hash.new {|hash,key| hash[key] = [] }
    case parse_type
    when "rexml"
      #puts "READING: " + pep_xml_file + " ..."
      doc = REXML::Document.new File.new(pep_xml_file)

      ## Create a hash of peptides based on sequence_charge (takes an array)
      doc.elements.each("msms_pipeline_analysis/msms_run_summary/search_result") do |result|
        pep_charge = result.attributes['assumed_charge']
        filename = result.attributes['spectrum']
        result.elements.to_a('search_hit').each do |hit|
          pep_seq = hit.attributes['peptide']
          seq_charge = [pep_seq, pep_charge]
          seq_charge_hash[seq_charge] << filename 
        end
      end
      seq_charge_hash
    when "regex"
      #puts "READING: " + pep_xml_file + " ..."
      ## Create a hash of peptides based on sequence_charge (takes an array)

      ## file from peptideAtlas:
      search_result_regex1 = /<spectrum_query spectrum="(.*\.\d+\.\d+\.\d)".* assumed_charge="(\d)"/o
      search_result_regex2 = /<search_result sxpectrum="(.*\.\d+\.\d+\.\d)".* assumed_charge="(\d)"/o
      search_hit_regex = /<search_hit .*peptide="(\w+)" /o

      peptide_h = {}
      filename = nil
      pep_charge = nil
      File.open(pep_xml_file).each do |line|
        if line =~ search_result_regex1
          filename = $1.dup
          pep_charge = $2.dup
        elsif line =~ search_result_regex2
          filename = $1.dup
          pep_charge = $2.dup
        end
        if line =~ search_hit_regex
          pep_seq = $1.dup
          seq_charge = [pep_seq, pep_charge]
          seq_charge_hash[seq_charge] << filename
        end
      end
    end
    seq_charge_hash
  end

  # drops all search_hits that have peptideprophet probability < min_val
  # and drops any search_results that end up with 0 search_hits
  def filter_by_min_pep_prob(file, outfile, min_val)
    root = root_el(file)

    d_search_hit = nil
    d_search_result = nil
    root.children.each do |child1|
      if child1.name == 'msms_run_summary'
        d_search_result = []
        child1.children.each do |child2|
          if child2.name == 'search_result'
            #puts "size before: " + child2.size.to_s
            d_search_hit = []
            child2.children.each do |child3|
              if child3.name == 'search_hit'
                child3.children.each do |child4|
                if child4.name == 'peptideprophet_result'
                  if child4.attrs["probability"].to_f < min_val
                    #puts "dropping probability: #{child4.attrs["probability"]}"
                    d_search_hit << child3
                  else
                    #puts "keeping probability: #{child4.attrs["probability"]}"
                  end
                end
                end
              end
            end
            d_search_hit.each do |to_drop|
              to_drop.drop
            end
            #puts "size after: " + child2.size.to_s
            if child2.size == 0
              d_search_result << child2
            end
          end
        end
        d_search_result.each do |to_drop|
          to_drop.drop
        end
      end
    end

    File.open(outfile, "w") do |fh|
      fh.print root.to_s
    end
  end
end   # Pep::Parser


# Class for parsing the '*-prot.xml' files in different ways
class Proph::Prot::Parser < Parser

  attr_accessor :prots
  attr_writer :peps

  def initialize
    @prots = []
  end

  # returns all the peptides from prots
  def peps
    unless @peps
      @peps = []
      @prots.each do |prot|
        @peps.push(*(prot.peps)) 
      end
    end
    @peps
  end


  # sets and returns an array of Prot objects
  # parse_type = "rexml" | "regex"
  def get_prots_and_peps(protxmlfile, prot_prob_cutoff=1.0, pep_init_prob_cutoff=1.0, pep_nsp_prob_cutoff=1.0, parse_type="rexml")
    ## ensure these are all floats
    (prot_prob_cutoff, pep_init_prob_cutoff, pep_nsp_prob_cutoff) = [prot_prob_cutoff, pep_init_prob_cutoff, pep_nsp_prob_cutoff].collect do |cutoff|
      cutoff.to_f
    end

    case parse_type
    when "rexml"
      doc = REXML::Document.new File.new(protxmlfile)
      doc.elements.each("protein_summary/protein_group/protein") do |elem|
        if elem.attributes['probability'].to_f >= prot_prob_cutoff
          prob = elem.attributes['probability'].to_f
          name= elem.attributes['protein_name']
          curr_prot = Prot.new({:probability => prob, :protein_name => name, :cutoff => prot_prob_cutoff})
          peptides = []
          elem.elements.to_a('peptide').each do |pep|
            if pep.attributes['nsp_adjusted_probability'].to_f >= pep_nsp_prob_cutoff && pep.attributes['initial_probability'].to_f >= pep_init_prob_cutoff
              nsp_prob = pep.attributes['nsp_adjusted_probability'].to_f
              sequence = pep.attributes['peptide_sequence']
              charge = pep.attributes['charge']
              pnm = pep.attributes['precursor_neutral_mass']
              peptides.push(Pep.new(:probability => nsp_prob, :sequence => sequence, :charge => charge, :precursor_neutral_mass => pnm, :nsp_cutoff => pep_nsp_prob_cutoff))
            end
            ## Only take proteins with peptides!
            if peptides.size > 0 
              curr_prot.peps = peptides
              @prots << curr_prot
            end
          end
        end
      end
    when "regex"
      prot_regex = /<protein protein_name="(.*)?" n_indistinguishable_proteins(.*)/o
      prot_prob_regex = /probability="([\d\.]+)"/o
      pep_regex = /<peptide peptide_sequence="(\w+)?"(.*)/o
      pep_else_regex = /charge="(\d)" initial_probability="([\d\.]+)" nsp_adjusted_probability="([\d\.]+)"/o

      curr_prot = nil
      peptides = []
      File.open(protxmlfile).each do |line|
        if line =~ prot_regex
          prob = nil
          name = $1.dup
          rest = $2
          if rest =~ prot_prob_regex
            prob = $1.dup
          end
          if curr_prot 
            if curr_prot.probability.to_f >= prot_prob_cutoff 
              if peptides.size > 0
                curr_prot.peps = peptides
                @prots.push(curr_prot)
              end
            end
          end
          curr_prot = Prot.new({:probability => prob, :protein_name => name, :cutoff => prot_prob_cutoff})
          peptides = []
        end
        if line =~ pep_regex
          sequence = $1.dup
          rest = $2
          if rest =~ pep_else_regex
            charge = $1
            init_prob = $2
            nsp_prob = $3
            if nsp_prob.to_f >= pep_nsp_prob_cutoff && init_prob.to_f >= pep_init_prob_cutoff
              peptides.push(Pep.new(:probability => nsp_prob, :sequence => sequence, :charge => charge, :nsp_cutoff => pep_nsp_prob_cutoff))
            end
          end
        end
        # get the last one:
        if curr_prot && curr_prot.probability.to_f > prot_prob_cutoff && peptides.size > 0
          curr_prot.peps = peptides
          @prots.push(curr_prot)
        end
      end
    end
    @prots
  end

end  # Prot::Parser

################ --END

=end
