require 'xml_style_parser'
require 'spec_id/sequest/pepxml'


module SpecID ; end
module SpecID::Parser ; end


class SpecID::Parser::PepProph
  include XMLStyleParser

  # gets the protein (and adds the pephit to the protein)
  def get_protein(search_hit, name, description, global_prot_hash)
    prot = 
      if global_prot_hash.key?(name)
        global_prot_hash[name]
      else
        prt = Proph::PepSummary::Prot.new([name, description, []])
        global_prot_hash[name] = prt
      end
    prot.peps << search_hit
    prot
  end

  def initialize(parse_type=:spec_id, version='3.0')
    @method = parse_type
    @version = version
    implemented = %w(AXML LibXML)
    klass_s = XMLStyleParser.available_xml_parsers.select {|v| implemented.include?(v) }.first
    case klass_s
    when 'AXML'
      @get_root_node_from_file = Proc.new do |file|
      AXML.parse_file(file)
      end
    when 'LibXML'  # LibXML is buggy on some machines...
      @get_root_node_from_file = Proc.new do |file| 
        doc = XML::Document.file(file)
        doc.root
      end
    else
      raise NotImplementedError, "Can only parse with #{implemented.join(', ')} right now"
    end
  end

  # returns the spec_id object
  # :global_prot_hash is a hash if you have multiple of these files to be
  # combined
  def spec_id(file, opts={})
    
    raise NotImplementedError, "cannot do #{@version} yet" if @version.nil? or @version < '3.0'
    spec_id_obj = 
      if x = opts[:spec_id]
        x 
      else
        Proph::PepSummary.new
      end
    global_prot_hash = 
      if y = opts[:global_prot_hash]
        y
      else
        {}
      end
    msms_pipeline_analysis_n = @get_root_node_from_file.call(file)
    spec_id_obj.peptideprophet_summary = msms_pipeline_analysis_n.find_first("descendant::peptideprophet_summary")


    spec_id_obj.msms_run_summaries = msms_pipeline_analysis_n.find('child::msms_run_summary').map do |msms_run_summary_n|
      parse_msms_run_summary(msms_run_summary_n, global_prot_hash)
    end

    peps = [] 
    spec_id_obj.msms_run_summaries.each do |mrs|
      mrs.spectrum_queries.each do |sq|
        sq.search_results.each do |sr|
          peps.push( *(sr.search_hits) )
        end
      end
    end
    spec_id_obj.peps = peps
    spec_id_obj.prots = global_prot_hash.values
    spec_id_obj
  end
  
  # returns an msms_run_summary object
  def parse_msms_run_summary(msms_run_summary_n, global_prot_hash)
    msms_run_summary_obj = Sequest::PepXML::MSMSRunSummary.new

    msms_run_summary_obj.from_pepxml_node(msms_run_summary_n)
    sample_enzyme_n = msms_run_summary_n.find_first("child::sample_enzyme")
    msms_run_summary_obj.sample_enzyme = SampleEnzyme.from_pepxml_node( sample_enzyme_n )

    search_summary_n = sample_enzyme_n.find_first("following-sibling::search_summary")
    spectrum_queries_nds = search_summary_n.find("following-sibling::spectrum_query")

    msms_run_summary_obj.spectrum_queries = spectrum_queries_nds.map do |sq_n|
      
      sq = Sequest::PepXML::SpectrumQuery.from_pepxml_node(sq_n) 
      sq.search_results = sq_n.children.map do |sr_n|   
        sr = Sequest::PepXML::SearchResult.new
        sr.search_hits = sr_n.children.map do |sh_n|
          sh = Proph::PepSummary::Pep.new  # descended from SearchHit
          sh.from_pepxml_node(sh_n)
          sh.spectrum_query = sq
          prots = [ get_protein(sh, sh_n['protein'], sh_n['protein_descr'], global_prot_hash) ]
          ## alternative proteins:
          if sh.num_tot_proteins > 1
            sh_n.find('child::alternative_protein').each do |alt_prot_n|
              prots << get_protein(sh, alt_prot_n['protein'], alt_prot_n['protein_descr'], global_prot_hash)
            end
          end
          sh.prots = prots

          if modinfo_node = sh_n.find_first("child::modification_info")
            sh.modification_info = Sequest::PepXML::SearchHit::ModificationInfo.from_pepxml_node(modinfo_node)
          end


          ## search scores:
          sh_n.find("child::search_score").each do |ss_n|
            case ss_n['name']
            when 'deltacnstar'
              sh.deltacnstar = ss_n['value'].to_i
            when 'xcorr'
              sh.xcorr = ss_n['value'].to_f
            when 'deltacn'
              sh.deltacn = ss_n['value'].to_f
            when 'spscore'
              sh.spscore = ss_n['value'].to_f
            when 'sprank'
              sh.sprank = ss_n['value'].to_i
            end
          end
          sh
        end
        sr
      end
      sq
    end

    ## NOTE: this is currently just the xml node!!!! TODO: wrap everything up
    #into a better search summary object (to eventually depracate the params object)
    msms_run_summary_obj.search_summary = msms_run_summary_n  
    msms_run_summary_obj
  end

end

class SpecID::Parser::ProtProph
  include XMLStyleParser
  Split_unique_stripped_peptides_re = /\+/

  def initialize(parse_type=:spec_id, version='4')
    @method = parse_type 
    @version = version
    
    implemented = %w(AXML LibXML)
    klass_s = XMLStyleParser.available_xml_parsers.select {|v| implemented.include?(v) }.first
    case klass_s
    when 'AXML'
      #puts "parsing with AXML (XMLParser based)" if $VERBOSE
      @get_root_node_from_file = Proc.new do |file|
        AXML.parse_file(file)
      end
    when 'LibXML'  # LibXML is buggy on some machines...
      #puts "parsing with LibXML" if $VERBOSE
      @get_root_node_from_file = Proc.new do |file| 
        doc = XML::Document.file(file)
        doc.root
      end
    else
      raise NotImplementedError, "Can only parse with #{implemented.join(', ')} right now"
    end
  end

  # returns the spec_id object
  def spec_id(file, opts={})
    raise NotImplementedError, "cannot do #{@version} yet" if @version != '4'
    spec_id_obj = 
      if x = opts[:spec_id]
        x 
      else
        Proph::ProtSummary.new
      end
    protein_summary_n = @get_root_node_from_file.call(file)

    #protein_summary_n = scan_for_first(doc, 'protein_summary')

    # protein_summary_header_n = protein_summary_n.child
    # could grab some of this info if we wanted...

    pep_hash = {}
    prot_hash = {}
    protein_groups = []

    # get all the proteins from inside protein groups
    protein_group_name = 'protein_group'
    get_protein_summary_header = true
    protein_summary_n.each do |protein_group_n|
      if get_protein_summary_header 
        protein_summary_header_n = protein_group_n
        get_protein_summary_header = false
      elsif protein_group_n.name == protein_group_name
        protein_groups << get_proteins(protein_group_n, pep_hash, prot_hash)
      end
    end

    # need to finalize hash stuff
    pep_hash.each do |k,pep|
      new_prots = []
      pep.prots.each do |prot_or_string|
        if prot_or_string.is_a?(Proph::Prot)
          new_prots << prot_or_string
        else
          prt = prot_hash[prot_or_string]
          if prt.nil?
            # this is an indistinguishable protein!
          else
            new_prots << prt
          end
        end
      end
      pep.prots = new_prots
    end

    spec_id_obj.peps = pep_hash.values
    spec_id_obj.prots = prot_hash.values
    spec_id_obj.prot_groups = protein_groups
    spec_id_obj
  end

  # takes a Y or N and gives true/false
  def booleanize(string)
    case string
    when 'Y'
      true
    when 'N'
      false
    else 
      nil
    end
  end

  # assumes that all the rest of the nodes are  protein_groups
  # pep_hash is hashed on aaseq OR modified peptide amino acid sequence (if
  # modified) + charge
  # (as far as I can tell, all protein entries are unique!)
  # returns a ProtGroup object
  def get_proteins(protein_group_node, pep_hash, prot_hash)
  
    protein_group_proteins = []

    protein_group_node.each do |protein_n|
      raise(Exception, "not expecting anything but protein's, got: #{protein_n.name}") if protein_n.name != 'protein'
      # probability peps protein_name n_indistinguishable_proteins percent_coverage unique_stripped_peptides group_sibling_id total_number_peptides pct_spectrum_ids description

      # get the description
      # INITIALIZE the protein and set key
      n = protein_n
      protein_name = n['protein_name']
      peps = []
      protein = Proph::Prot.new( [protein_name, n['probability'].to_f, 
                      n['n_indistinguishable_proteins'].to_i,
                      n['percent_coverage'].to_f, 
                      n['unique_stripped_peptides'].split(Split_unique_stripped_peptides_re),
                      n['group_sibling_id'], n['total_number_peptides'].to_i, 
                      n['pct_spectrum_ids'].to_f, nil,
                      peps ])
      protein_group_proteins << protein
      prot_hash[protein_name] = protein

      # traverse through the peptides (and annotation)
      protein_n.each do |protein_sub_n|
        # create a proteins array for each peptide
        proteins = [protein]

        if protein_sub_n.name == 'annotation'
          protein.description = protein_sub_n['protein_description']
        end
        if protein_sub_n.name == 'peptide'
          peptide_n = protein_sub_n
          # peptide_sequence charge initial_probability nsp_adjusted_probability weight is_nondegenerate_evidence n_enzymatic_termini n_sibling_peptides n_sibling_peptides_bin n_instances is_contributing_evidence calc_neutral_pep_mass modification_info prots
          # get modifications, if any

          n = peptide_n
          peptide_sequence = n['peptide_sequence']
          charge = n['charge'].to_i
          
          # GET list of all proteins and modifications

          mod_info = nil
          peptide_hash_string = peptide_sequence
          if peptide_n.child?
            peptide_n.each do |pep_sub_n|
              case pep_sub_n.name
              when 'peptide_parent_protein'
                # NOTE! the proteins list will have strings until the assoc.
                # prot is found!
                proteins << pep_sub_n['protein_name']
              when 'modification_info'
                masses = pep_sub_n.map do |mod_aa_mass_n|
                Sequest::PepXML::SearchHit::ModificationInfo::ModAminoacidMass.new([mod_aa_mass_n['position'].to_i, mod_aa_mass_n['mass'].to_f])
                end
                peptide_hash_string = pep_sub_n['modified_peptide']
              mod_info = Sequest::PepXML::SearchHit::ModificationInfo.new([peptide_hash_string, masses])
              end
            end
          end

          key = [peptide_hash_string, charge]
          peptide = 
            if pep_hash.key? key
              pep_hash[key]
            else
              pep = Proph::Prot::Pep.new([peptide_sequence, charge, 
                             n['initial_probability'].to_f, n['nsp_adjusted_probability'].to_f, 
                             n['weight'].to_f, booleanize(n['is_nondegenerate_evidence']), 
                             n['n_enzymatic_termini'].to_i, n['n_sibling_peptides'].to_f, 
                             n['n_sibling_peptides'].to_i, n['n_instances'].to_i, 
                             booleanize(n['is_contributing_evidence']), 
                             n['calc_neutral_pep_mass'].to_f, mod_info, proteins] )
              pep_hash[key] = pep
              pep
            end
          peps << peptide
        end
      end  # end protein children
    end
    Proph::ProtGroup.new(:prots => protein_group_proteins, :group_number => protein_group_node['group_number'].to_i, :probability => protein_group_node['probability'].to_f)
  end

  def parse(file, opts)
    send(@method, file, opts)
  end

end
