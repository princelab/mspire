
require 'sample_enzyme'
require 'ms/parser/mzxml'
require 'hash_by'
require 'set_from_hash'
require 'spec_id/bioworks'
require 'instance_var_set_from_hash'
require 'ms/msrun'
require 'spec_id/srf'
require 'spec_id/sequest/params'
require 'fileutils'

class Numeric
  # returns a string with a + or - on the front
  def to_plus_minus_string
    if self >= 0
      '+' << self.to_s
    else
      self.to_s
    end
  end
end


module Sequest ; end
class Sequest::PepXML; end

class Sequest::PepXML::MSMSPipelineAnalysis
  include SpecIDXML
  # Version 1.2.3
  attr_writer :date
  attr_writer :xmlns, :xmlns_xsi, :xsi_schemaLocation
  attr_accessor :summary_xml 
  # Version 2.3.4
  attr_writer :xmlns, :xmlns_xsi, :xsi_schema_location
  attr_accessor :pepxml_version
  attr_accessor :msms_run_summary

  # if block given, sets msms_run_summary to block
  def initialize(hash=nil)
    @xmlns = nil
    @xmlns_xsi = nil
    @xsi_schema_location = nil
    if hash
      self.set_from_hash(hash)
    end
    if block_given?
      @msms_run_summary = yield
    end
  end

  # if no date string given, then it will set to Time.now
  def date
    if @date ; @date 
    else
      case Sequest::PepXML.pepxml_version
      when 18 ;  tarr = Time.now.to_a ; tarr[3..5].reverse.join('-') + "T#{tarr[0..2].reverse.join(':')}"
      end
    end
  end

  def xmlns
    if @xmlns ; @xmlns
    else ; "http://regis-web.systemsbiology.net/pepXML"
    end
  end

  def xmlns_xsi
    if @xmlns_xsi ; @xmlns_xsi
    else ; "http://www.w3.org/2001/XMLSchema-instance"
    end
  end

  def xsi_schema_location
    if @xsi_schema_location ; @xsi_schema_location 
    else ; "http://regis-web.systemsbiology.net/pepXML /tools/bin/TPP/tpp/schema/pepXML_v18.xsd"
    end
  end

  def to_pepxml
    case Sequest::PepXML.pepxml_version
    when 18
      element_xml_and_att_string(:msms_pipeline_analysis, "date=\"#{date}\" xmlns=\"#{xmlns}\" xmlns:xsi=\"#{xmlns_xsi}\" xsi:schemaLocation=\"#{xsi_schema_location}\" summary_xml=\"#{summary_xml}\"") do
        @msms_run_summary.to_pepxml
      end
    else
      abort "Don't know how to deal with version: #{Sequest::PepXML.pepxml_version}"
    end
  end

end

class Sequest::PepXML::MSMSRunSummary
  include SpecID
  include SpecIDXML

  # the version of TPP you are using (determines xml output)
  # The name of the pep xml file (without extension) (but this is a long
  # filename!!!)
  attr_accessor :base_name
  # The name of the mass spec manufacturer 
  attr_accessor :ms_manufacturer
  attr_accessor :ms_model
  attr_accessor :ms_mass_analyzer
  attr_accessor :ms_detector
  attr_accessor :raw_data_type
  attr_accessor :raw_data
  attr_accessor :ms_ionization
  attr_accessor :pepxml_version

  # A SampleEnzyme object (responds to: name, cut, no_cut, sense)
  attr_accessor :sample_enzyme
  # A SearchSummary object
  attr_accessor :search_summary
  # An array of spectrum_queries
  attr_accessor :spectrum_queries

  # takes a hash of name, value pairs
  # if block given, spectrum_queries (should be array of spectrum queries) is
  # set to the return value of the block
  def initialize(hash=nil)
    @spectrum_queries = []
    if hash
      instance_var_set_from_hash(hash)
    end
    if block_given? ; @spectrum_queries = yield end
  end

  def to_pepxml
    case Sequest::PepXML.pepxml_version
    when 18
      element_xml_and_att_string(:msms_run_summary, "base_name=\"#{base_name}\" msManufacturer=\"#{ms_manufacturer}\" msModel=\"#{ms_model}\" msIonization=\"#{ms_ionization}\" msMassAnalyzer=\"#{ms_mass_analyzer}\" msDetector=\"#{ms_detector}\" raw_data_type=\"#{raw_data_type}\" raw_data=\"#{raw_data}\"") do
        sample_enzyme.to_pepxml +
          search_summary.to_pepxml +
          spectrum_queries.map {|sq| sq.to_pepxml }.join
      end
    end
  end

  def search_hit_class
    Sequest::PepXML::SearchHit
  end

  def self.from_pepxml_node(node)
    self.new.from_pepxml_node(node)
  end

  # peps correspond to search_results
  def from_pepxml_node(node)
    @base_name = node['base_name']
    @ms_manufacturer = node['msManufacturer']
    @ms_model = node['msModel']
    @ms_manufacturer = node['msIonization']
    @ms_mass_analyzer = node['msMassAnalyzer']
    @ms_detector = node['msDetector']
    @raw_data_type = node['raw_data_type']
    @raw_data = node['raw_data']
    self
  end
end



class Sequest::PepXML
  include SpecIDXML

  ## CREATE a default version for the entire class
  class << self
    attr_accessor :pepxml_version
  end
  DEF_VERSION = 18
  self.pepxml_version = DEF_VERSION # default version

  attr_accessor :pepxml_version, :msms_pipeline_analysis
  ## the full path name (no extension)
  attr_accessor :base_name
  attr_accessor :h_plus
  attr_accessor :avg_parent

  #attr_accessor :spectrum_queries, :params, :base_name, :search_engine, :database, :raw_data_type, :raw_data, :out_data_type, :out_data, :sample_enzyme, :pepxml_version

  # returns an array of spectrum queries
  def spectrum_queries
    msms_pipeline_analysis.msms_run_summary.spectrum_queries
  end

  # msms_pipeline_analysis is set to the result of the yielded block
  # and set_mono_or_avg is called with params if given
  def initialize(pepxml_version=DEF_VERSION, sequest_params_obj=nil)
    self.class.pepxml_version = pepxml_version
    if sequest_params_obj
      set_mono_or_avg(sequest_params_obj)
    end
    if block_given?
      @msms_pipeline_analysis = yield
      @base_name = @msms_pipeline_analysis.msms_run_summary.base_name
    end
  end

  # sets @h_plus and @avg_parent from the sequest params object
  def set_mono_or_avg(sequest_params_obj)
    case sequest_params_obj.precursor_mass_type
    when "monoisotopic" ; @avg_parent = false
    else ; @avg_parent = true
    end

    case @avg_parent
    when true ; @h_plus = SpecID::AVG[:h_plus]
    when false ; @h_plus = SpecID::MONO[:h_plus]
    end
  end

  def date
    Time.new.to_s
  end

  def xml_version 
    '<?xml version="1.0" encoding="UTF-8"?>' + "\n"
  end

  # for pepxml_version == 0
  def doctype
    '<!DOCTYPE msms_pipeline_analysis SYSTEM "/usr/bin/msms_analysis3.dtd">' + "\n"
  end

  def style_sheet
    case self.class.pepxml_version
    when 18
    '<?xml-stylesheet type="text/xsl" href="/tools/bin/TPP/tpp/schema/pepXML_std.xsl"?>'
    end
  end

  def header
    case self.class.pepxml_version
    when 18 ; xml_version + style_sheet
    end
  end

  # updates the private attrs _num_prots and _first_prot on bioworks pep
  # objects.  Ideally, we'd like these attributes to reside elsewhere, but for
  # memory concerns, this is best for now.
  def self._prot_num_and_first_prot_by_pep(pep_array)
    pep_array.hash_by(:aaseq).each do |aasq, pep_arr|
      prts = []
      pep_arr.each { |pep| prts.push( *(pep.prots) ) }
      prts.uniq!
      _size = prts.size 
      pep_arr.each do |pep|
        pep._num_prots = _size
        pep._first_prot = prts.first
      end
    end
  end


Default_Options = {
    :out_path => '.',
    #:backup_db_path => '.',
    # a PepXML option
    :pepxml_version => DEF_VERSION,  
    ## MSMSRunSummary options:
    # string must be recognized in sample_enzyme.rb 
    # or create your own SampleEnzyme object
    :ms_manufacturer => 'ThermoFinnigan',
    :ms_model => 'LCQ Deca XP Plus',
    :ms_ionization => 'ESI',
    :ms_mass_analyzer => 'Ion Trap',
    :ms_detector => 'UNKNOWN',
    :ms_data => '.',      # path to ms data files (raw or mzxml)
    :raw_data_type => "raw",
    :raw_data => ".mzXML", ## even if you don't have it?
    ## SearchSummary options:
    :out_data_type => "out", ## may be srf?? don't think pepxml recognizes this yet
    :out_data => ".tgz", ## may be srf??
    :copy_mzxml => false, # copy the mzxml file to the out_path (create it if necessary)
    :print => false, # print the objects to file
  }

  # will dynamically set :ms_model and :ms_mass_analyzer from srf info
  # (ignoring defaults or anything passed in) for LTQ Orbitrap
  # and LCQ Deca XP
  # See SRF::Sequest::PepXML::Default_Options hash for defaults
  # unless given, the out_path will be given as the path of the srf_file
  # srf may be an object or a filename
  def self.new_from_srf(srf, opts={})
    opts = Default_Options.merge(opts)

    ## read the srf file
    if srf.is_a? String
      srf = SRF.new(srf)
    end

    ## set the outpath
    out_path = opts.delete(:out_path)

    params = srf.params

    ## check to see if we need backup_db
    backup_db_path = opts.delete(:backup_db_path)
    if !File.exist?(params.database) && backup_db_path
      params.database_path = backup_db_path
    end

    #######################################################################
    # PREPARE THE OPTIONS:
    #######################################################################
    ## remove items from the options hash that don't belong to 
    ppxml_version = opts.delete(:pepxml_version)
    out_data_type = opts.delete(:out_data_type)
    out_data = opts.delete(:out_data)

    ## Extract meta info from srf
    bn_noext = base_name_noext(srf.header.raw_filename)
    opts[:ms_model] = srf.header.model
    case opts[:ms_model]
    when /Orbitrap/
      opts[:ms_mass_analyzer] = 'Orbitrap'
    when /LCQ Deca XP/
      opts[:ms_mass_analyzer] = 'Ion Trap'
    end

    ## Create the base name
    full_base_name_no_ext = make_base_name( File.expand_path(out_path), bn_noext)
    opts[:base_name] = full_base_name_no_ext

    ## Create the search summary:
    search_summary_options = {
      :search_database => Sequest::PepXML::SearchDatabase.new(params),
      :base_name => full_base_name_no_ext,
      :out_data_type => out_data_type,
      :out_data => out_data
    }
    modifications_string = srf.header.modifications
    search_summary = Sequest::PepXML::SearchSummary.new( params, modifications_string, search_summary_options)

    # create the sample enzyme from the params object:
    sample_enzyme_obj = 
      if opts[:sample_enzyme]
        opts[:sample_enzyme]
      else
        params.sample_enzyme
      end
    opts[:sample_enzyme] = sample_enzyme_obj

    ## Create the pepxml obj and top level objects
    pepxml_obj = Sequest::PepXML.new(ppxml_version, params) 
    pipeline = Sequest::PepXML::MSMSPipelineAnalysis.new({:date=>nil,:summary_xml=> bn_noext +'.xml'})
    pepxml_obj.msms_pipeline_analysis = pipeline
    pipeline.msms_run_summary = Sequest::PepXML::MSMSRunSummary.new(opts)
    pipeline.msms_run_summary.search_summary = search_summary
    modifications_obj = search_summary.modifications

    ## name some common variables we'll need
    h_plus = pepxml_obj.h_plus
    avg_parent = pepxml_obj.avg_parent


    ## COPY MZXML FILES IF NECESSARY
    if opts[:copy_mzxml]
      mzxml_pathname_noext = File.join(opts[:ms_data], bn_noext)
      to_copy = MS::Converter::MzXML.file_to_mzxml(mzxml_pathname_noext)
      if to_copy
        FileUtils.cp to_copy, out_path
      else
        puts "Couldn't file mzXML file with base: #{mzxml_pathname_noext}"
        puts "Perhaps you need to specifiy the location of the raw data"
        puts "or need an mzXML converter (readw or t2x)"
        exit
      end
    end


    #######################################################################
    # CREATE the spectrum_queries_ar
    #######################################################################
    srf_index = srf.index
    out_files = srf.out_files
    spectrum_queries_arr = Array.new(srf.dta_files.size)
    files_with_hits_index = 0  ## will end up being 1 indexed

    deltacn_orig = opts[:deltacn_orig]
    deltacn_index = 
      if deltacn_orig ; 20
      else 19
      end

    srf.dta_files.each_with_index do |dta_file,dta_i|
      next if out_files[dta_i].num_hits == 0
      files_with_hits_index += 1

      precursor_neutral_mass = dta_file.mh - h_plus

      (start_scan, end_scan, charge) = srf_index[dta_i]
      sq_hash = {
        :spectrum => [bn_noext, start_scan, end_scan, charge].join('.'),
        :start_scan => start_scan,
        :end_scan => end_scan,
        :precursor_neutral_mass => precursor_neutral_mass,
        :assumed_charge => charge.to_i,
        :pepxml_version => ppxml_version,
        :index => files_with_hits_index,
      }

      spectrum_query = Sequest::PepXML::SpectrumQuery.new(sq_hash)


      hits = out_files[dta_i].hits

      search_hits = 
        if opts[:all_hits]
          Array.new(out_files[dta_i].num_hits)  # all hits
        else
          Array.new(1)  # top hit only
        end

      (0...(search_hits.size)).each do |hit_i|
        hit = hits[hit_i]
        # under the modified deltacn schema (like bioworks)
        # Get proper deltacn and deltacnstar
        # under new srf, deltacn is already corrected for what prophet wants,
        # deltacn_orig_updated is how to access the old one
        # Prophet deltacn is not the same as the native Sequest deltacn
        # It is the deltacn of the second best hit!

        ## mass calculations:
        calc_neutral_pep_mass = hit[0] - h_plus


        sequence = hit.sequence

        #  NEED TO MODIFY SPLIT SEQUENCE TO DO MODS!
        ## THIS IS ALL INNER LOOP, so we make every effort at speed here:
        (prevaa, pepseq, nextaa) = SpecID::Pep.prepare_sequence(sequence)
        # 0=mh 1=deltacn_orig 2=sp 3=xcorr 4=id 5=num_other_loci 6=rsp 7=ions_matched 8=ions_total 9=sequence 10=prots 11=deltamass 12=ppm 13=aaseq 14=base_name 15=first_scan 16=last_scan 17=charge 18=srf 19=deltacn 20=deltacn_orig_updated

        sh_hash = {
          :hit_rank => hit_i+1,
          :peptide => pepseq,
          :peptide_prev_aa => prevaa,
          :peptide_next_aa => nextaa,
          :protein => hit[10].first.reference.split(" ").first, 
          :num_tot_proteins => hit[10].size,
          :num_matched_ions => hit[7],
          :tot_num_ions => hit[8],
          :calc_neutral_pep_mass => calc_neutral_pep_mass,
          :massdiff => precursor_neutral_mass - calc_neutral_pep_mass, 
          :num_tol_term => sample_enzyme_obj.num_tol_term(sequence),
          :num_missed_cleavages => sample_enzyme_obj.num_missed_cleavages(pepseq),
          :is_rejected => 0,
          # These are search score attributes:
          :xcorr => hit[3],
          :deltacn => hit[deltacn_index],
          :spscore => hit[2],
          :sprank => hit[6],
          :modification_info => modifications_obj.modification_info(SpecID::Pep.split_sequence(sequence)[1]),
        }
        unless deltacn_orig
          sh_hash[:deltacnstar] = 
            if hits[hit_i+1].nil?  # no next hit? then its deltacnstar == 1
            '1'
            else
            '0'
            end
        end
        search_hits[hit_i] = Sequest::PepXML::SearchHit.new(sh_hash) # there can be multiple hits
      end

      search_result = Sequest::PepXML::SearchResult.new
      search_result.search_hits = search_hits
      spectrum_query.search_results = [search_result]
      spectrum_queries_arr[files_with_hits_index] = spectrum_query
    end
    spectrum_queries_arr.compact!

    pipeline.msms_run_summary.spectrum_queries = spectrum_queries_arr 
    pepxml_obj.base_name = pipeline.msms_run_summary.base_name
    pipeline.msms_run_summary.spectrum_queries =  spectrum_queries_arr 

    pepxml_obj
  end

  # takes an .srg or bioworks.xml file
  # if possible, ensures that an mzXML file is present for each pepxml file
  # :print => true, will print files
  # NOTES: num_tol_term and num_missing_cleavages are both calculated from the
  # sample_enzyme.  Thus, a No_Enzyme search may still pass in a
  # :sample_enzyme option to get these calculated.
  def self.set_from_bioworks(bioworks_file, opts={})
    opts = Default_Options.merge(opts)
    ## Create the out_path directory if necessary

      unless File.exist? opts[:out_path]
        FileUtils.mkpath(opts[:out_path])
      end
      unless File.directory? opts[:out_path]
        abort "#{opts[:out_path]} must be a directory!"
      end

      spec_id = SpecID.new(bioworks_file)
      pepxml_objs = 
        if spec_id.is_a? Bioworks
          abort("must have opts[:params] set!") unless opts[:params]
          set_from_bioworks_xml(bioworks_file, opts[:params], opts)
        elsif spec_id.is_a? SRFGroup
          spec_id.srfs.map do |srf|
            new_from_srf(srf, opts) 
          end
        else
          abort "invalid object"
        end

      if opts[:print]
        pepxml_objs.each do |obj|
          obj.to_pepxml(obj.base_name + ".xml")
        end
      end
      pepxml_objs
    end


    # Takes bioworks 3.2/3.3 xml output (with no filters)
    # Returns a list of PepXML objects
    # params = sequest.params file
    # bioworks = bioworks.xml exported multi-consensus view file
    # pepxml_version = 0 for tpp 1.2.3
    # pepxml_version = 18 for tpp 2.8.2, 2.8.3, 2.9.2
  def self.set_from_bioworks_xml(bioworks, params, opts={})
    opts = Default_Options.merge(opts)
    pepxml_version, ms_manufacturer, ms_model, ms_ionization, ms_mass_analyzer, ms_detector, raw_data_type, raw_data, out_data_type, out_data, ms_data, out_path = opts.values_at(:pepxml_version, :ms_manufacturer, :ms_model, :ms_ionization, :ms_mass_analyzer, :ms_detector, :raw_data_type, :raw_data, :out_data_type, :out_data, :ms_data, :out_path)



    unless out_path
      out_path = '.'
    end

    supported_versions = [18]

    unless supported_versions.include?(opts[:pepxml_version]) 
      abort "pepxml_version: #{pepxml_version} not currently supported.  Current support is for versions #{supported_versions.join(', ')}"
    end

    ## Turn params and bioworks_obj into objects if necessary:
    # Params:
    if params.class == Sequest::Params  # OK!
    elsif params.class == String ; params = Sequest::Params.new(params)
    else                         ; abort "Don't recognize #{params} as object or string!"
    end
    # Bioworks:
    if bioworks.class == Bioworks  # OK!
    elsif bioworks.class == String ; bioworks = SpecID.new(bioworks)
    else                           ; abort "Don't recognize #{bioworks} as object or string!"
    end

    sample_enzyme_obj = 
      if opts[:sample_enzyme]
        opts[:sample_enzyme]
      else
        params.sample_enzyme
      end

    #puts "bioworks.peps.size: #{bioworks.peps.size}"; #puts "bioworks.prots.size: #{bioworks.prots.size}"; #puts "Bioworks.version: #{bioworks.version}"

    ## TURN THIS ON IF YOU THINK YOU MIGHT NOT BE GETTING PEPTIDES from
    ## bioworks
    #bioworks.peps.each { |pep| if pep.class != Bioworks::Pep ; puts "trying to pass as pep: "; p pep; abort "NOT a pep!" end }

    ## check to see if we need backup_db

    backup_db_path = opts.delete(:backup_db_path)
    if !File.exist?(params.database) && backup_db_path
      params.database_path = backup_db_path
    end

    ## Start
    split_bio_objs = []

    ## (num_prots_by_pep, prot_by_pep) = 
    #num_prots_by_pep.each do |k,v| puts "k: #{k} v: #{v}\n"; break end ; prot_by_pep.each do |k,v| puts "k: #{k} v: #{v}" ; break end ; abort "HERE"

    modifications_string = bioworks.modifications

    ## Create a hash of spectrum_query arrays by filename (this very big block):
    spectrum_queries_by_base_name = {}
    # Hash by the filenames to split into filenames:
    pepxml_objects = bioworks.peps.hash_by(:base_name).map do |base_name, pep_arr|

      search_summary = Sequest::PepXML::SearchSummary.new(params, modifications_string, {:search_database => Sequest::PepXML::SearchDatabase.new(params), :out_data_type => out_data_type, :out_data => out_data})
      modifications_obj = search_summary.modifications

      pepxml_obj = Sequest::PepXML.new(pepxml_version, params)
      full_base_name_no_ext = self.make_base_name( File.expand_path(out_path), base_name)

      case pepxml_version
      when 18
        pipeline =  Sequest::PepXML::MSMSPipelineAnalysis.new({:date=>nil,:summary_xml=>base_name+'.xml'})
        msms_run_summary = Sequest::PepXML::MSMSRunSummary.new({
          :base_name => full_base_name_no_ext,
          :ms_manufacturer => ms_manufacturer,
          :ms_model => ms_model,
          :ms_ionization => ms_ionization,
          :ms_mass_analyzer => ms_mass_analyzer,
          :ms_detector => ms_detector,
          :raw_data_type => raw_data_type,
          :raw_data => raw_data,
          :sample_enzyme => sample_enzyme_obj, # usually, params.sample_enzyme,
          :search_summary => search_summary,
        }) 
        pipeline.msms_run_summary = msms_run_summary
        pepxml_obj.msms_pipeline_analysis = pipeline
        pepxml_obj.msms_pipeline_analysis.msms_run_summary.search_summary.base_name =  full_base_name_no_ext
        pepxml_obj.base_name = full_base_name_no_ext
        pepxml_obj 
      end

      # Create a hash by pep object containing num_tot_proteins
      # This is only valid if all hits are present (no previous thresholding)
      # Since out2summary only acts on one folder at a time,
      # we should only do it for one folder at a time! (that's why we do this
      # here instead of globally)
      self._prot_num_and_first_prot_by_pep(pep_arr)
      prec_mz_arr = nil
      case x = bioworks.version
      when /3.2/ 
        calc_prec_by = :prec_mz_arr
        # get the precursor_mz array for this filename
        mzxml_file = MS::Converter::MzXML.file_to_mzxml(File.join(ms_data, base_name))
        prec_mz_arr = MS::MSRun.precursor_mz_by_scan_num(mzxml_file)
      when /3.3/
        calc_prec_by = :deltamass
      else
        abort "invalid BioworksBrowser version: #{x}"
      end

      if opts[:copy_mzxml]
        to_copy = MS::Converter::MzXML.file_to_mzxml(File.join(ms_data, base_name))
        if to_copy
          FileUtils.cp to_copy, out_path
        end
      end


      spectrum_queries_ar = pep_arr.hash_by(:first_scan, :last_scan, :charge).map do |key,arr|


        # Sort_by_rank and take the top hit (to mimick out2summary):

        arr = arr.sort_by {|pep| pep.xcorr.to_f } # ascending
        top_pep = arr.pop
        second_hit = arr.last # needed for deltacnstar


        case calc_prec_by
        when :prec_mz_arr
          precursor_neutral_mass = Sequest::PepXML::SpectrumQuery.calc_precursor_neutral_mass(calc_prec_by, top_pep.first_scan.to_i, top_pep.last_scan.to_i, prec_mz_arr, top_pep.charge, pepxml_obj.avg_parent)
        when :deltamass
          precursor_neutral_mass = Sequest::PepXML::SpectrumQuery.calc_precursor_neutral_mass(calc_prec_by, top_pep.mass.to_f, top_pep.deltamass.to_f, pepxml_obj.avg_parent)
        end

        calc_neutral_pep_mass = (top_pep.mass.to_f - pepxml_obj.h_plus)

        # deltacn & star:
        # (NOTE: OLD?? out2summary wants the deltacn of the 2nd best hit.)
        if second_hit 
          #top_pep.deltacn = second_hit.deltacn 
          deltacnstar = '0'
        else 
          top_pep.deltacn = '1.0'
          deltacnstar = '1'
        end
        # Create the nested structure of queries{results{hits}}
        # (Ruby's blocks work beautifully for things like this)
        spec_query = Sequest::PepXML::SpectrumQuery.new({
          :spectrum => [top_pep.base_name, top_pep.first_scan, top_pep.last_scan, top_pep.charge].join("."),
          :start_scan => top_pep.first_scan,
          :end_scan => top_pep.last_scan,
          :precursor_neutral_mass => precursor_neutral_mass,
          :assumed_charge => top_pep.charge,
          :pepxml_version => pepxml_version,
        }) 


        search_result = Sequest::PepXML::SearchResult.new 
        #puts "set MASSDIFF: "
        #p precursor_neutral_mass - calc_neutral_pep_mass
        ## Calculate some interdependent values;
        # NOTE: the bioworks mass is reallyf M+H if two or more scans went
        # into the search_hit; calc_neutral_pep_mass is simply the avg of
        # precursor masses adjusted to be neutral
        (prevaa, pepseq, nextaa) = SpecID::Pep.prepare_sequence(top_pep.sequence)
        (num_matched_ions, tot_num_ions) = Sequest::PepXML::SearchHit.split_ions(top_pep.ions)
        search_hit = Sequest::PepXML::SearchHit.new({
          :hit_rank => 1,
          :peptide => pepseq,
          :peptide_prev_aa => prevaa,
          :peptide_next_aa => nextaa,
          :protein => top_pep._first_prot.reference.split(" ").first, 
          :num_tot_proteins => top_pep._num_prots,
          :num_matched_ions => num_matched_ions,
          :tot_num_ions => tot_num_ions,
          :calc_neutral_pep_mass => calc_neutral_pep_mass,
          :massdiff => precursor_neutral_mass - calc_neutral_pep_mass,
          :num_tol_term => sample_enzyme_obj.num_tol_term(top_pep.sequence),
          :num_missed_cleavages => sample_enzyme_obj.num_missed_cleavages(pepseq),
          :is_rejected => 0,
          # These are search score attributes:
          :xcorr => top_pep.xcorr,
          :deltacn => top_pep.deltacn,
          :deltacnstar => deltacnstar,
          :spscore => top_pep.sp,
          :sprank => top_pep.rsp,
          :modification_info => modifications_obj.modification_info(SpecID::Pep.split_sequence(top_pep.sequence)[1]),
          :spectrum_query => spec_query,
        })
        search_result.search_hits = [search_hit] # there can be multiple search hits
        spec_query.search_results = [search_result]  # can be multiple search_results
        spec_query
      end

      # create an index by spectrum as results end up typically in out2summary
      # (I really dislike this order, however)
      spectrum_queries_ar = spectrum_queries_ar.sort_by {|pep| pep.spectrum }
      spectrum_queries_ar.each_with_index {|res,index| res.index = "#{index + 1}" }
      pipeline.msms_run_summary.spectrum_queries = spectrum_queries_ar
      pepxml_obj
    end ## collects pepxml_objs
    # summary_xml is the short basename of the pepxml file (e.g., "020.xml")
    pepxml_objects.sort_by {|obj| obj.summary_xml }
  end

  def summary_xml
    base_name + ".xml"
  end

  def precursor_mass_type
    @params.precursor_mass_type
  end

  def fragment_mass_type
    @params.fragment_mass_type
  end

  # combines filename in a manner consistent with the path
  def self.make_base_name(path, filename)
    sep = '/'
    if path.split('/').size < path.split("\\").size
      sep = "\\"
    end
    if path.split('').last == sep
      path + File.basename(filename)
    else
      path + sep + File.basename(filename)
    end
  end

  # outputs pepxml, (to file if given)
  def to_pepxml(file=nil)
    string = header
    string << @msms_pipeline_analysis.to_pepxml

    if file
      File.open(file, "w") do |fh| fh.print string end
    end
    string
  end

  # given any kind of filename (from windows or whatever)
  # returns the base of the filename with no file extension
  def self.base_name_noext(file)
    file.gsub!("\\", '/')
    File.basename(file).sub(/\.[\w^\.]+$/, '')
  end


end # PepXML


class Sequest::PepXML::SearchResult
  include SpecIDXML
  # an array of search_hits
  attr_accessor :search_hits

  # if block given, then search_hits set to return value
  def initialize(search_hits = [])
    @search_hits = search_hits
  end

  def to_pepxml
    element_xml_no_atts(:search_result) do
      @search_hits.map {|sh| sh.to_pepxml }.join
    end
  end

end

class Sequest::PepXML::SearchSummary
  include SpecIDXML
  attr_accessor :params
  attr_accessor :base_name
  attr_accessor :out_data_type
  attr_accessor :out_data
  # by default, "1"
  attr_accessor :search_id
  attr_accessor :modifications
  # A SearchDatabase object (responds to :local_path and :type)
  attr_accessor :search_database
  # if given a sequest params object, then will set the following attributes:
  # args is a hash of parameters
  # modifications_string -> See Modifications
  def initialize(prms=nil, modifications_string='', args=nil)
    @search_id = "1"
    if prms
      @params = prms
      @modifications = Sequest::PepXML::Modifications.new(prms, modifications_string)
    end
    if args ; set_from_hash(args) end
  end

  def method_missing(symbol, *args)
    if @params ; @params.send(symbol, *args) end
  end

  def to_pepxml
    element_xml(:search_summary, [:base_name, :search_engine, :precursor_mass_type, :fragment_mass_type, :out_data_type, :out_data, :search_id]) do
      search_database.to_pepxml +
        if @params.enzyme =~ /^No_Enzyme/
          ''
        else
          short_element_xml(:enzymatic_search_constraint, [:enzyme, :max_num_internal_cleavages, :min_number_termini])
        end +
        @modifications.to_pepxml +
        Sequest::PepXML::Parameters.new(@params).to_pepxml
    end
  end

  def self.from_pepxml_node(node)
    self.new.from_pepxml_node(node)
  end

  def from_pepxml_node(node)
    raise NotImplementedError, "right now we just have the xml node at your disposal"
  end

end

class Sequest::PepXML::Parameters
  include SpecIDXML

  attr_accessor :params
  
  def initialize(obj=nil)
    @params = obj
  end
  #  (used to be called pepxml_parameters)
  # Returns xml in the form <parameter name="#{method_name}"
  # value="#{method_value}"/> for list of symbols
  def to_pepxml
    keys_as_symbols = @params.opts.sort.map do |k,v| k.to_s end
    params_xml(@params, *keys_as_symbols)
    # (:peptide_mass_tol, :peptide_mass_units, :fragment_ion_tol, :ion_series, :max_num_differential_AA_per_mod, :nucleotide_reading_frame, :num_output_lines, :remove_precursor_peak, :ion_cutoff_percentage, :match_peak_count, :match_peak_allowed_error, :match_peak_tolerance, :protein_mass_filter, :sequence_header_filter)
  end
end

class Sequest::PepXML::Modifications
  include SpecIDXML

  # sequest params object
  attr_accessor :params
  # array holding AAModifications 
  attr_accessor :aa_mods
  # array holding TerminalModifications
  attr_accessor :term_mods
  # a hash of all differential modifications present by aa_one_letter_symbol
  # and special_symbol. This is NOT the mass difference but the total mass {
  # 'M*' => 155.5, 'S@' => 190.3 }.  NOTE: Since the termini are dependent on
  # the amino acid sequence, they are give the *differential* mass.  The
  # termini are given the special symbol as in sequest e.g. '[' => 12.22, #
  # cterminus    ']' => 14.55 # nterminus
  attr_accessor :masses_by_diff_mod_hash
  # a hash, key is [AA_one_letter_symbol.to_sym, difference.to_f]
  # values are the special_symbols
  attr_accessor :mod_symbols_hash

  # The modification symbols string looks like this:
  # (M* +15.90000) (M# +29.00000) (S@ +80.00000) (C^ +12.00000) (ct[ +12.33000) (nt] +14.20000)
  # ct is cterminal peptide (differential)
  # nt is nterminal peptide (differential)
  # the C is just cysteine
  # will set_modifications and masses_by_diff_mod hash
  def initialize(params=nil, modification_symbols_string='')
    @params = params
    if @params
      set_modifications(params, modification_symbols_string)
    end
  end

  # set the masses_by_diff_mod and mod_symbols_hash from 
  def set_hashes(modification_symbols_string)

    @mod_symbols_hash = {}
    @masses_by_diff_mod = {}
    if (modification_symbols_string == nil || modification_symbols_string == '')
      return nil
    end
    table = @params.mass_table
    modification_symbols_string.split(/\)\s+\(/).each do |mod|
      if mod =~ /\(?(\w+)(.) (.[\d\.]+)\)?/
        if $1 == 'ct' || $1 == 'nt' 
          mass_diff = $3.to_f
          @masses_by_diff_mod[$2] = mass_diff
          @mod_symbols_hash[[$1.to_sym, mass_diff]] = $2.dup
          # changed from below to match tests, is this right?
          # @mod_symbols_hash[[$1, mass_diff]] = $2.dup
        else
          symbol_string = $2.dup 
          mass_diff = $3.to_f
          $1.split('').each do |aa|
            aa_as_sym = aa.to_sym
            @masses_by_diff_mod[aa+symbol_string] = mass_diff + table[aa_as_sym]
            @mod_symbols_hash[[aa_as_sym, mass_diff]] = symbol_string
          end
        end
      end
    end
  end

  # given a bare peptide (no end pieces) returns a ModificationInfo object
  # e.g. given "]PEPT*IDE", NOT 'K.PEPTIDE.R'
  # if there are no modifications, returns nil
  def modification_info(peptide)
    if @masses_by_diff_mod.size == 0
      return nil
    end
    hash = {}
    hash[:modified_peptide] = peptide.dup
    hsh = @masses_by_diff_mod  
    table = @params.mass_table
    h = table[:h]  # this? or h_plus ??
    oh = table[:o] + h
    ## only the termini can match a single char
    if hsh.key? peptide[0,1]
      # AA + H + differential_mod
      hash[:mod_nterm_mass] = table[peptide[1,1].to_sym] + h + hsh[peptide[0,1]]
      peptide = peptide[1...(peptide.size)]
    end
    if hsh.key? peptide[(peptide.size-1),1]
      # AA + OH + differential_mod
      hash[:mod_cterm_mass] = table[peptide[(peptide.size-2),1].to_sym] + oh + hsh[peptide[-1,1]]
      peptide.slice!( 0..-2 )
      peptide = peptide[0...(peptide.size-1)]
    end
    mod_array = []
    (0...peptide.size).each do |i|
      if hsh.key? peptide[i,2]
        mod_array << Sequest::PepXML::SearchHit::ModificationInfo::ModAminoacidMass.new([ i+1 , hsh[peptide[i,2]] ])
      end
    end
    if mod_array.size > 0
      hash[:mod_aminoacid_masses] = mod_array
    end
    if hash.size > 1  # if there is more than just the modified peptide there
      Sequest::PepXML::SearchHit::ModificationInfo.new(hash)
      #Sequest::PepXML::SearchHit::ModificationInfo.new(hash.values_at(:modified_peptide, :mod_aminoacid_masses, :mod_nterm_mass, :mod_cterm_mass)
    else
      nil
    end
  end

  # returns an array of static mod objects and static terminal mod objects
  def create_static_mods(params)

    ####################################
    ## static mods
    ####################################

    static_mods = [] # [[one_letter_amino_acid.to_sym, add_amount.to_f], ...]
    static_terminal_mods = [] # e.g. [add_Cterm_peptide, amount.to_f]

    params.mods.each do |k,v|
      v_to_f = v.to_f
      if v_to_f != 0.0
        if k =~ /add_(\w)_/
          static_mods << [$1.to_sym, v_to_f]
        else
          static_terminal_mods << [k, v_to_f]
        end
      end
    end
    aa_hash = params.mass_table

    ## Create the static_mods objects
    static_mods.map! do |mod|
      hash = {
        :aminoacid => mod[0].to_s,
        :massdiff => mod[1],
        :mass => aa_hash[mod[0]] + mod[1],
        :variable => 'N',
        :binary => 'Y',
      } 
      Sequest::PepXML::AAModification.new(hash)
    end

    ## Create the static_terminal_mods objects
    static_terminal_mods.map! do |mod|
      terminus = if mod[0] =~ /Cterm/ ; 'c'
                 else                 ; 'n' # only two possible termini
                 end
      protein_terminus = case mod[0] 
                         when /Nterm_protein/ ; 'n'
                         when /Cterm_protein/ ; 'c'
                         else nil
                         end

      # create the hash                            
      hash = {
        :terminus => terminus,
        :massdiff => mod[1],
        :variable => 'N',
        :description => mod[0],
      }
      hash[:protein_terminus] = protein_terminus if protein_terminus
      Sequest::PepXML::TerminalModification.new(hash)
    end
    [static_mods, static_terminal_mods]
  end

  # 1. sets aa_mods and term_mods from a sequest params object
  # 2. sets @params
  # 3. sets @masses_by_diff_mod
  def set_modifications(params, modification_symbols_string)
    @params = params

    set_hashes(modification_symbols_string)
    (static_mods, static_terminal_mods) = create_static_mods(params)

    aa_hash = params.mass_table
    #################################
    # Variable Mods:
    #################################
    arr = params.diff_search_options.rstrip.split(/\s+/)
    # [aa.to_sym, diff.to_f]
    variable_mods = []
    (0...arr.size).step(2) do |i|
      if arr[i].to_f != 0.0
        variable_mods << [arr[i+1], arr[i].to_f]
      end
    end
    mod_objects = []
    variable_mods.each do |mod|
      mod[0].split('').each do |aa|
        hash = {
          
          :aminoacid => aa,
          :massdiff => mod[1],
          :mass => aa_hash[aa.to_sym] + mod[1],
          :variable => 'Y',
          :binary => 'N',
          :symbol => @mod_symbols_hash[[aa.to_sym, mod[1]]],
        }
        mod_objects << Sequest::PepXML::AAModification.new(hash)
      end
    end
    variable_mods = mod_objects
    #################################
    # TERMINAL Variable Mods:
    #################################
    # These are always peptide, not protein termini (for sequest)
    (nterm_diff, cterm_diff) = params.term_diff_search_options.rstrip.split(/\s+/).map{|v| v.to_f }

    to_add = []
    if nterm_diff != 0.0
      to_add << ['n',nterm_diff.to_plus_minus_string, @mod_symbols_hash[:nt, nterm_diff]]
    end
    if cterm_diff != 0.0
      to_add << ['c', cterm_diff.to_plus_minus_string, @mod_symbols_hash[:ct, cterm_diff]]
    end

    variable_terminal_mods = to_add.map do |term, mssdiff, symb|
      hash = {
        :terminus => term,
        :massdiff => mssdiff,
        :variable => 'Y',
        :symbol => symb,
      }
      Sequest::PepXML::TerminalModification.new(hash)
    end

    #########################
    # COLLECT THEM
    #########################
    @aa_mods = static_mods + variable_mods
    @term_mods = static_terminal_mods + variable_terminal_mods
  end

  ## Generates the pepxml for static and differential amino acid mods based on
  ## sequest object
  def to_pepxml
    st = ''
    if @aa_mods
      st << @aa_mods.map {|v| v.to_pepxml }.join
    end
    if @term_mods
      st << @term_mods.map {|v| v.to_pepxml }.join
    end
    st
  end

end

# Modified aminoacid, static or variable
# unless otherwise stated, all attributes can be anything
class Sequest::PepXML::AAModification
  include SpecIDXML

  # The amino acid (one letter code)
  attr_accessor :aminoacid
  # Must be a string!!!!
  # Mass difference with respect to unmodified aminoacid, must begin with
  # either + (nonnegative) or - [e.g. +1.05446 or -2.3342]
  # consider Numeric#to_plus_minus_string at top
  attr_accessor :massdiff
  # Mass of modified aminoacid
  attr_accessor :mass
  # Y if both modified and unmodified aminoacid could be present in the
  # dataset, N if only modified aminoacid can be present
  attr_accessor :variable
  # whether modification can reside only at protein terminus (specified 'n',
  # 'c', or 'nc')
  attr_accessor :peptide_terminus
  # MSial symbol used by search engine to designate this modification
  attr_accessor :symbol
  # Y if each peptide must have only modified or unmodified aminoacid, N if a
  # peptide may contain both modified and unmodified aminoacid
  attr_accessor :binary

  def initialize(hash=nil)
    instance_var_set_from_hash(hash) if hash # can use unless there are weird methods
  end

  def to_pepxml
    # note massdiff
    short_element_xml_and_att_string("aminoacid_modification", "aminoacid=\"#{aminoacid}\" massdiff=\"#{massdiff.to_plus_minus_string}\" mass=\"#{mass}\" variable=\"#{variable}\" peptide_terminus=\"#{peptide_terminus}\" symbol=\"#{symbol}\" binary=\"#{binary}\"")
  end

end

# Modified aminoacid, static or variable
class Sequest::PepXML::TerminalModification
  include SpecIDXML

  # n for N-terminus, c for C-terminus
  attr_accessor :terminus
  # Mass difference with respect to unmodified terminus
  attr_accessor :massdiff
  # Mass of modified terminus
  attr_accessor :mass
  # Y if both modified and unmodified terminus could be present in the
  # dataset, N if only modified terminus can be present
  attr_accessor :variable
  # MSial symbol used by search engine to designate this modification
  attr_accessor :symbol
  # whether modification can reside only at protein terminus (specified n or
  # c)
  attr_accessor :protein_terminus
  attr_accessor :description

  def initialize(hash=nil)
    instance_var_set_from_hash(hash) if hash # can use unless there are weird methods
  end

  def to_pepxml
    #short_element_xml_from_instance_vars("terminal_modification")
    short_element_xml_and_att_string("terminal_modification", "terminus=\"#{terminus}\" massdiff=\"#{massdiff.to_plus_minus_string}\" mass=\"#{mass}\" variable=\"#{variable}\" symbol=\"#{symbol}\" protein_terminus=\"#{protein_terminus}\" description=\"#{description}\"")
  end
end


class Sequest::PepXML::SearchDatabase
  include SpecIDXML 
  attr_accessor :local_path
  attr_writer :seq_type
  # Takes a SequestParams object
  # Sets :local_path from the params object attr :database
  def initialize(params=nil, args=nil)
    @seq_type = nil
    if params
      @local_path = params.database
    end
    if args ; set_from_hash(args) end
  end

  def seq_type
    if @seq_type ; @seq_type
    else
      if @local_path =~ /\.fasta/
        'AA'
      else
        abort "Don't recognize type from your database local path: #{@local_path}"
      end
    end
  end

  def to_pepxml
    short_element_xml_and_att_string(:search_database, "local_path=\"#{local_path}\" type=\"#{seq_type}\"")
  end

end

Sequest::PepXML::SpectrumQuery = Arrayclass.new(%w(spectrum start_scan end_scan precursor_neutral_mass index assumed_charge search_results pepxml_version))

class Sequest::PepXML::SpectrumQuery
  include SpecIDXML

  ############################################################
  # FOR PEPXML:
  ############################################################
  def to_pepxml
    case Sequest::PepXML.pepxml_version
    when 18
      element_xml("spectrum_query", [:spectrum, :start_scan, :end_scan, :precursor_neutral_mass, :assumed_charge, :index]) do
        search_results.collect { |sr| sr.to_pepxml }.join
      end
    end
  end

  def self.from_pepxml_node(node)
    self.new.from_pepxml_node(node)
  end

  def from_pepxml_node(node)
    self[0] = node['spectrum']
    self[1] = node['start_scan'].to_i
    self[2] = node['end_scan'].to_i
    self[3] = node['precursor_neutral_mass'].to_f
    self[4] = node['index'].to_i
    self[5] = node['assumed_charge'].to_i
    self
  end

  # Returns the precursor_neutral based on the scans and an array indexed by
  # scan numbers.  first and last scan and charge should be integers.
  # This is the precursor_mz - h_plus!
  # by=:prec_mz_arr|:deltamass
  # if prec_mz_arr then the following arguments must be supplied:
  # :first_scan = int, :last_scan = int, :prec_mz_arr = array with the precursor
  # m/z for each product scan, :charge = int
  # if deltamass then the following arguments must be supplied:
  # m_plus_h = float, deltamass = float
  # For both flavors, a final additional argument 'average_weights'
  # can be used.  If true (default), average weights will be used, if false, 
  # monoisotopic weights (currently this is simply the mass of the proton)
  def self.calc_precursor_neutral_mass(by, *args)
    average_weights = true
    case by
    when :prec_mz_arr
      (first_scan, last_scan, prec_mz_arr, charge, average_weights) = args
    when :deltamass
      (m_plus_h, deltamass, average_weights) = args
    end

    if average_weights 
      mass_h_plus = SpecID::AVG[:h_plus] 
    else
      mass_h_plus = SpecID::MONO[:h_plus] 
    end

    case by
    when :prec_mz_arr
      mz = nil
      if first_scan != last_scan
        sum = 0.0
        tot_num = 0
        (first_scan..last_scan).each do |scan|
          val = prec_mz_arr[scan]
          if val  # if the scan is not an mslevel 2
            sum += val
            tot_num += 1
          end
        end
        mz = sum/tot_num
      else
        mz = prec_mz_arr[first_scan]
      end
      charge * (mz - mass_h_plus)
    when :deltamass
      m_plus_h - mass_h_plus + deltamass
    else
      abort "don't recognize 'by' in calc_precursor_neutral_mass: #{by}"
    end
  end

end


Sequest::PepXML::SearchHit = Arrayclass.new( %w( hit_rank peptide peptide_prev_aa peptide_next_aa protein num_tot_proteins num_matched_ions tot_num_ions calc_neutral_pep_mass massdiff num_tol_term num_missed_cleavages is_rejected deltacnstar xcorr deltacn spscore sprank modification_info spectrum_query) )

# 0=hit_rank 1=peptide 2=peptide_prev_aa 3=peptide_next_aa 4=protein 5=num_tot_proteins 6=num_matched_ions 7=tot_num_ions 8=calc_neutral_pep_mass 9=massdiff 10=num_tol_term 11=num_missed_cleavages 12=is_rejected 13=deltacnstar 14=xcorr 15=deltacn 16=spscore 17=sprank 18=modification_info 19=spectrum_query

class Sequest::PepXML::SearchHit
  include SpecID::Pep
  include SpecIDXML

  Non_standard_amino_acid_char_re = /[^A-Z\.\-]/

  def aaseq ; self[1] end
  def aaseq=(arg) ; self[1] = arg end

  # These are all search_score elements:

  # 1 if there is no second ranked hit, 0 otherwise

  tmp_verb = $VERBOSE
  $VERBOSE = nil
  def initialize(hash=nil)
    super(self.class.size)
    if hash
      self[0,20] = [hash[:hit_rank], hash[:peptide], hash[:peptide_prev_aa], hash[:peptide_next_aa], hash[:protein], hash[:num_tot_proteins], hash[:num_matched_ions], hash[:tot_num_ions], hash[:calc_neutral_pep_mass], hash[:massdiff], hash[:num_tol_term], hash[:num_missed_cleavages], hash[:is_rejected], hash[:deltacnstar], hash[:xcorr], hash[:deltacn], hash[:spscore], hash[:sprank], hash[:modification_info], hash[:spectrum_query]]
    end
    self
  end
  $VERBOSE = tmp_verb

  undef_method :inspect
  def inspect
    var = @@attributes.map do |m| "#{m}:#{self.send(m)}" end.join(" ")
    "#<SearchHit #{var}>"
  end

  # Takes ions in the form XX/YY and returns [XX.to_i, YY.to_i]
  def self.split_ions(ions)
    ions.split("/").map {|ion| ion.to_i }
  end

  def search_score_xml(symbol)
    "#{tabs}<search_score name=\"#{symbol}\" value=\"#{send(symbol)}\"/>"
  end

  def search_scores_xml(*symbol_list)
    symbol_list.collect do |sy|
      search_score_xml(sy)
    end.join("\n") + "\n"
  end

  def to_pepxml
    mod_pepxml = 
      if self[18]
        self[18].to_pepxml
      else
        ''
      end

    #string = element_xml_and_att_string("search_hit", [:hit_rank, :peptide, :peptide_prev_aa, :peptide_next_aa, :protein, :num_tot_proteins, :num_matched_ions, :tot_num_ions, :calc_neutral_pep_mass, :massdiff_as_string, :num_tol_term, :num_missed_cleavages, :is_rejected]) do
    # note the to_plus_minus_string
    #puts "MASSDIFF:"
    #p massdiff
    element_xml_and_att_string("search_hit", "hit_rank=\"#{hit_rank}\" peptide=\"#{peptide}\" peptide_prev_aa=\"#{peptide_prev_aa}\" peptide_next_aa=\"#{peptide_next_aa}\" protein=\"#{protein}\" num_tot_proteins=\"#{num_tot_proteins}\" num_matched_ions=\"#{num_matched_ions}\" tot_num_ions=\"#{tot_num_ions}\" calc_neutral_pep_mass=\"#{calc_neutral_pep_mass}\" massdiff=\"#{massdiff.to_plus_minus_string}\" num_tol_term=\"#{num_tol_term}\" num_missed_cleavages=\"#{num_missed_cleavages}\" is_rejected=\"#{is_rejected}\"") do
      mod_pepxml +
        search_scores_xml(:xcorr, :deltacn, :deltacnstar, :spscore, :sprank)
    end
  end

  def from_pepxml_node(node)
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

end


Sequest::PepXML::SearchHit::ModificationInfo = Arrayclass.new(%w(modified_peptide mod_aminoacid_masses mod_nterm_mass mod_cterm_mass))

# Positions and masses of modifications
class Sequest::PepXML::SearchHit::ModificationInfo
  include SpecIDXML

  ## Should be something like this:
  # <modification_info mod_nterm_mass=" " mod_nterm_mass=" " modified_peptide=" ">
  #   <mod_aminoacid_mass position=" " mass=" "/>
  # </modification_info>

  alias_method :masses, :mod_aminoacid_masses
  alias_method :masses=, :mod_aminoacid_masses=

  # Mass of modified N terminus<
  #attr_accessor :mod_nterm_mass
  # Mass of modified C terminus<
  #attr_accessor :mod_cterm_mass
  # Peptide sequence (with indicated modifications)  I'm assuming that the
  # native sequest indicators are OK here
  #attr_accessor :modified_peptide

  # These are objects of type: ...ModAminoacidMass
  # position ranges from 1 to peptide length
  #attr_accessor :mod_aminoacid_masses

  # Will escape any xml special chars in modified_peptide
  def to_pepxml
    ## Collect the modifications:
    mod_strings = []
    if masses and masses.size > 0
      mod_strings = masses.map do |ar|
        "position=\"#{ar[0]}\" mass=\"#{ar[1]}\""
      end
    end
    ## Create the attribute string:
    att_parts = []
    if mod_nterm_mass
      att_parts << "mod_nterm_mass=\"#{mod_nterm_mass}\""
    end
    if mod_cterm_mass
      att_parts << "mod_cterm_mass=\"#{mod_cterm_mass}\""
    end
    if modified_peptide
      att_parts << "modified_peptide=\"#{escape_special_chars(modified_peptide)}\""
    end
    element_xml_and_att_string('modification_info', att_parts.join(" ")) do
      mod_strings.map {|st| short_element_xml_and_att_string('mod_aminoacid_mass', st) }.join
    end
  end

  def self.from_pepxml_node(node)
    self.new.from_pepxml_node(node)
  end

  # returns self
  def from_pepxml_node(node)
    self[0] = node['modified_peptide'] 
    self[2] = node['mod_nterm_mass']
    self[3] = node['mod_cterm_mass']
    masses = []
    node.children do |mass_n|
      masses << Sequest::PepXML::SearchHit::ModificationInfo::ModAminoacidMass.new([mass_n['position'].to_i, mass_n['mass'].to_f])
    end
    self[1] = masses
    self 
  end

  ## 

  # <modification_info modified_peptide="GC[546]M[147]PSKEVLSAGAHR">
  # <mod_aminoacid_mass position="2" mass="545.7160"/>
  # <mod_aminoacid_mass position="3" mass="147.1926"/>
  # </modification_info>
end

Sequest::PepXML::SearchHit::ModificationInfo::ModAminoacidMass = Arrayclass.new(%w(position mass))
