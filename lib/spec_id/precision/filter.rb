require 'sort_by_attributes'
require 'validator'
require 'spec_id'
require 'merge_deep'
require 'spec_id/precision/filter/interactive'
require 'spec_id/precision/filter/output'


class Filter
  
  # filters using previously passed in methods and options
  def filter(group)
    if @opts
      send(@method, group, *@opts)
    else
      send(@method, group)
    end
  end

  # replaces the contents of group with what passed
  def filter!(group)
    group.replace(filter(group))
  end
end



# we have to require this after we setup our defaults hash
# require 'filter/spec_id/cmdline'

class SpecID::Precision::Filter 
  FV_DEFAULTS = {
    :sequest => 
    {
      :xcorr1 => 1.0, 
      :xcorr2 => 1.5,
      :xcorr3 => 2.0,
      :deltacn => 0.1,
      :ppm => 1000,
      :include_deltacnstar => true,
    },


    # output
    :proteins => false,
    :output => [],

    # general
    :top_hit_by => :xcorr,
    :postfilter => :top_per_scan,
    :prefilter => false,
    :hits_together => true,

    # These are also defaulted in the commandline because they are necessary
    # for the validators...  could this introduce conflicts somehow?
    :decoy_on_match => true,
    :ties => true,

    # UNLISTED FOR NOW:
    :include_ties_in_top_hit_prefilter => true,
    :include_ties_in_top_hit_postfilter => false,
  }

  require 'spec_id/precision/filter/cmdline'

  def filter_and_validate_cmdline(args)
    (spec_id_obj, options, option_parser) = CmdlineParser.new.parse(args)
    if spec_id_obj == nil
      puts option_parser
      return
    end
    final_answer = SpecID::Precision::Filter.new.filter_and_validate(spec_id_obj, options)
  end

    #  # output_array has doublets of [format, handle]
    #  # answer is the answer one gets out of filter_and_validate
    #  def output(answer, output_array)
    #    output_array.each do |format, handle|
    #      SpecID::Precision::Filter::Output.new(format, handle)
    #    end
    #  end

  # Very high level method that takes simple parameters.
  # spec_id may be a filename or a SpecID object (containing peps)
  # Default values may be queried from SpecID::Precision::Filter::FV_DEFAULTS
  # Returns a structured hash: 
  #  Fl = Float ; Ar = Array
  # { :params => <Hash of filtering params>,
  #   :pephits => <Ar of pephits>,
  #   :pephits_precision => [<array of precision>]
  #      # if :proteins => true
  #   :prothits => <Array of prothits>,
  #   :prothits_precision => [ Array of hashes where each hash =   
  #                             { :worst => Fl, :normal => Fl,
  #                             :normal_stdev => Fl } ]
  # }
  #
  # NOTE: Brackets [] indicate an Array! The Bar '|' indicates another option.
  # The asterik '*' is the default option.
  #
  # :sequest => {
  #   :xcorr1 -> >= (xcorr +1 charge state)
  #   :xcorr2 -> >= (xcorr +2 charge state)
  #   :xcorr3 -> >= (xcorr +3 charge state)
  #   :deltacn -> >= (delta cn)
  #   :ppm -> <= parts per million (Float)
  #   :include_deltacnstar => *true | false  include deltacn (given at 1.1) of
  #                                          top hit with no 2nd hit
  #
  # }
  # OUTPUT:
  #   :proteins => true | *false    gives proteins (and validation)
  #   :output => [[format, FILENAME=nil],...]  formats to output filtering results.
  #                                            can be used multiple times
  #                                            FILENAME is the filename to use
  #                                            if nil, then outputs to $stdout
  #                                            valid formats are:
  #                                            :text_table   (default)
  #                                            :yaml         (need to implement)
  #                                            :protein_summary (need to implement)
  #                                            :html_table   (need to implement)
  #                                            default value =>
  #                                            [[:text_table,nil]]
  #
  # VALIDATION:
  #   :validators => [Array]  objects that respond to pephit_precision
  #                           usually of base class Validator
  #                           NOTE: if you have decoy peptides, you MUST have
  #                           a Validator::Decoy object to separate them out.
  #                           NOTE: if transmem validator passed in, the
  #                           proteins in spec_id must already be granted
  #                           transmem status!
  #                           
  #
  # OTHER:
  #   :top_hit_by -> *:xcorr | :probability
  #                   probabilities only in bioworks.xml files right now (if
  #                   they were calculated).
  #   :postfilter -> *:top_per_scan | :top_per_aaseq | :top_per_aaseq_charge 
  #                   :top_per_scan hashes by filename + scan
  #                   :top_per_aaseq hashes by top_per_scan + aaseq
  #                   :top_per_aaseq_charge hashes by top_per_aaseq + charge
  #   :prefilter -> true | *false    Takes top hit per file+scan+charge
  #   :interactive => interactive_object
  #        # should behave like this:
  #        # interactive_object.filter_args(currentopts) -> args_for_filtering | nil (done)
  #        
  #        # interactive_object.passing(final_answer)

  # The defaults for filter_and_validate

  def filter_and_validate(spec_id_obj, options={})
    # NOTE:
    # This is a fairly complicated method.  The complication comes in doing
    # top hit filters on separate/cat searches wanted them to be either
    # together or separate.  I opt for fewer conversions between the two, but
    # that means keeping track of more things...
    
    opts = FV_DEFAULTS.merge_deep(options)

    spec_id = spec_id_obj

    peps = spec_id.peps
    filename = spec_id.filename

    #######################################
    # DEFAULTS:
    interactive_changing_keys = [:xcorr1, :xcorr2, :xcorr3, :deltacn, :ppm, :include_deltacnstar, :postfilter]
    interactive_shortcut_map = {
      :xcorr1 => 'x1',
      :xcorr2 => 'x2',
      :xcorr3 => 'x3',
      :deltacn => 'dcn',
      :ppm => 'ppm',
      :include_deltacnstar => 'dcns',
      :postfilter => 'pf',
    }
    to_float = proc {|x| x.to_f}
    to_bool = proc do |x|
      case x
      when /^t/io
        true
      when /^f/io
        false
      when true
        true
      when false
        false
      else
        nil
      end
    end
    to_postfilter = proc do |x|
      case x
      when 's'
        :top_per_scan
      when 'a'
        :top_per_aaseq
      when 'ac'
        :top_per_aaseq_charge
      when Symbol
        x
      end
    end
    casting_map = {
      :xcorr1 => to_float,
      :xcorr2 => to_float,
      :xcorr3 => to_float,
      :deltacn => to_float,
      :ppm => to_float,
      :include_deltacnstar => to_bool,
      :postfilter => to_postfilter,
    }
   
    # output:  
    # NOTE: BOOLEANS that are by default false do not need a default!!
    # They will yield false on key lookup if no key or false!
    # BOOLEANS that by default are true should be queried like this
    # !(opts[:<option>] == false)

    # open up each of the files for writing
    if opts[:output]
      outputs = opts[:output].map do |format, where|
        if where == nil
          where = $stdout
        end
        SpecID::Precision::Filter::Output.new(format, where)
      end
    end

    postfilters_per_hash = {
      :top_per_scan => [:base_name, :first_scan],
      :top_per_aaseq => [:aaseq],  # first by top_per_scan, then this guy
      :top_per_aaseq_charge => [:aaseq, :charge], # first by top_per_scan, then this one
    }

    top_hit_by__to_sort_by = {
      :xcorr => [:xcorr, {:down=> [:xcorr]}],
      :probability => [:probability, (spec_id.hi_prob_best ? {:down=> [:probability]} : {})],
    }
    sort_by_att_opts = top_hit_by__to_sort_by[opts[:top_hit_by]]
    opts_for_top_hit_prefilter = {
      :per => [:base_name, :first_scan, :charge], 
      :by => sort_by_att_opts, 
      :include_ties => opts[:include_ties_in_top_hit_prefilter]
    }
    # PRIVATE DEFAULTS:
    merge_prefix = 'DECOY_'
    unmerge_regexp = /^DECOY_/

    #######################################


    # opts_decoy = opts[:decoy]


    
    # if we have a Validator::Decoy object, we will use its defaults to split
    # peptides.
    decoy_validator = 
      if opts[:validators]
        decoy_vals = opts[:validators].select {|v| v.class == Validator::Decoy }
        if decoy_vals.size == 0
          nil
        elsif decoy_vals.size == 1
          decoy_vals.first
        else
          raise ArgumentError, "can only have one Validator::Decoy object"
        end

        ### suck out the relevant parameters
        #sep_params = [:decoy_on_match, :correct_wins].inject({}) do |hash,k|
        #  hash[k] = decoy_validator.send(k)
        #  hash
        #end
      else
        nil
      end

    decoy_validator_to_split_with = nil

    pep_sets = 
      if decoy_validator
        if decoy_validator.constraint.is_a?(Regexp)
          if opts[:hits_together]
            decoy_validator_to_split_with = decoy_validator
            [peps]
          else
            (target, decoy) = decoy_validator.partition(peps)
            #(target, decoy) = SpecID.classify_by_prot(peps, opts_decoy, sep_params[:decoy_on_match], sep_params[:correct_wins])
            [target, decoy]
          end
        elsif decoy_validator.constraint.is_a?(String)  ## a Filename 
          decoy_peps = SpecID.new(decoy_validator.constraint).peps
          
          if opts[:hits_together]
            # we fake that the protein sets are together
            decoy_validator_to_split_with = Validator::Decoy.new(:constraint => unmerge_regexp)
            decoy_peps.each do |pep|
              pep.prots.each {|prt| prt.reference = merge_prefix + prt.reference }
            end
            [peps + decoy_peps] # wrap them so we get the target out
          else
            [peps, decoy_peps]
          end
        else 
          raise ArgumentError, "Decoy::Validator#constraint must be a Regexp or valid SpecID file"
        end
      else
        [peps]  # no decoy
      end

    # This method doesn't seem to do so well, but a person can use a different 
    # one and enter in their own custom pi_0 value!
    #if opts[:decoy_pi_zero]
    #  if pep_sets.size < 2
    #    raise ArgumentError, "must have a decoy validator for pi zero calculation!"
    #  end
    #  require 'pi_zero'
    #  (_target, _decoy) = pep_sets
    #  pvals = PiZero.p_values_for_sequest(*pep_sets).sort
    #  pi_zero = PiZero.pi_zero(pvals)
    #  opts[:decoy_pi_zero] = PiZero.pi_zero(pvals)
    #end

    if opts[:proteins]
      protein_validator = Validator::ProtFromPep.new
    end

    ### TOP HITS PREFILTER < < TOP_HITS_TOGETHER > >
    ###########################
    # TOP HITS FILTER:
    ###########################
    # REALLY, this guy only exists for speed and memory consumption
    # If we prefilter, we don't have to filter as many hits in every
    # interactive round.  I'd leave this guy out if I were doing only a
    # sequest filter.  (I should compare results with this filter and w/o)
    # This guy is very tricky since we need to consider whether they are to be
    # run together or separately and not do more work than we need
    # get passed_target for any case (and passed_decoy if opts[:decoy])

    
    top_hit_prefilter = SpecID::Precision::Filter::Peps.new(:top_hit, opts_for_top_hit_prefilter)  if opts[:prefilter]

    if top_hit_prefilter
      pep_sets.map! do |pep_set|
        top_hit_prefilter.filter(pep_set)
      end
    end

    # prepare our top hit filter:
    # since we are now modulating this guy, we need to create it fresh every
    # time
    top_per_scan_postfilter = SpecID::Precision::Filter::Peps.new(:top_hit, 
                                                  :per => postfilters_per_hash[:top_per_scan],
                                                  :by => sort_by_att_opts, 
                                                  :include_ties => opts[:include_ties_in_top_hit_postfilter])



    # Prepare to loop
    # Give interactive help once here if necessary
    interactive = opts[:interactive]
    if interactive
      ARGV.clear
      interactive.out(interactive.interactive_help(interactive_changing_keys, interactive_shortcut_map)) if interactive.verbose
    end

    # the loop is for if we are interactive
    final_answer = nil
    loop do  

      if interactive #interactive
        # a bit of a hack, but we shove on the postfilter param to modulate
        opts[:sequest][:postfilter] = opts[:postfilter]
        response = interactive.filter_args(opts[:sequest], interactive_changing_keys, interactive_shortcut_map, casting_map)
        opts[:postfilter] = opts[:sequest].delete(:postfilter)
        break if response == nil
      end

      # prepare our top hit filter:
      # since we are now modulating this guy, we need to create it fresh every
      # time
      
      sub_postfilter = 
        if opts[:postfilter] == :top_per_scan
          nil
        else
          postfilter_per_args = postfilters_per_hash[opts[:postfilter]]
          SpecID::Precision::Filter::Peps.new(:top_hit, 
                                   :per => postfilter_per_args,
                                   :by => sort_by_att_opts, 
                                   :include_ties => opts[:include_ties_in_top_hit_postfilter]
                                  )
        end

      pep_sets_to_be_filtered = pep_sets.map 

      ### SEQUEST < EITHER >
      ###########################
      # SEQUEST FILTER:
      ###########################
      # This guy is immune to the trickiness of top hits, so we just filter
      # separately since validation is best done without decoys (except decoy)
      sequest_args = opts[:sequest].values_at( :xcorr1, :xcorr2, :xcorr3, :deltacn, :ppm, :include_deltacnstar )
      sequest_filter = SpecID::Precision::Filter::Peps.new(:standard_sequest_filter, *sequest_args)

      pep_sets_filtered = pep_sets_to_be_filtered.map do |pep_set|
        sequest_filter.filter(pep_set)
      end

      ### FINAL HIT PER SCAN < < TOP_HITS_TOGETHER > >
      ##########################
      # FINAL HIT PER SCAN
      ##########################
      # Why not just do the top hit filter in the top hits pre filter before?
      # Good question.  Answer: We may have instances when the top hit (by
      # xcorr) has some other poorer attribute than the hit at the other charge.
      # In this case, we'd end up with no passing peptide. 
      # Also, the xcorr filter is per charge, so we may filter out the higher
      # scoring peptide hit even though the other would pass based on its charge
      # state, etc., etc....
      # ###################################################
      # NOTE THIS WELL:
      # IF IT IS SUPPOSE TO be separate it's *ALREADY* separate, if together its
      # *ALREADY* together!!!!
      # the implication is that we don't need to do any merging or
      # separating before we do this last filter!!!!
      # ###################################################

      # TODO: We need to add this guy in!
      #if opts[:uniq_aa]
      #  pep_sets_filtered.map do |pep_set|
      #  end
      #end

      pep_sets_filtered.map! do |pep_set|
        top_per_scan_postfilter.filter!(pep_set)
        if sub_postfilter
          sub_postfilter.filter!(pep_set) 
        else
          pep_set
        end
      end

      normal_post_filtered_peps = pep_sets_filtered.first

      # separate the decoy's out if they are together
      if decoy_validator_to_split_with  # only set if opts[:hits_together]!!
        (target, decoy) = decoy_validator_to_split_with.partition(normal_post_filtered_peps)
        pep_sets_filtered = [target, decoy]
      end

      ### VALIDATION < SEPARATE >
      pephit_precision_array = get_pephit_precision(opts[:validators], *pep_sets_filtered) if opts[:validators]

      final_answer = {
        :params => opts,
        :pephits => pep_sets_filtered.first, 
      }
      if pephit_precision_array
        final_answer[:pephits_precision] = pephit_precision_array
      end

      if opts[:proteins]       
        protein_precision_array = peptide_precision_to_protein_precision(protein_validator, normal_post_filtered_peps, pephit_precision_array)
        # this could be factored out (since we do it in protein_precision)

        # merge the final prots into a unique set:
        final_answer[:prothits] = normal_post_filtered_peps.inject(Set.new) do |protset, pep|
          protset.merge(pep.prots)
        end
        final_answer[:prothits_precision] = protein_precision_array
      end

      ## output the output
      outputs.each {|output| output.print(final_answer) }

      if interactive
        interactive.passing(opts, final_answer)
      end

      if !interactive
        break
      end
    end
    # Close the filehandles
    outputs.each { |output| output.close } if opts[:output]
    final_answer
  end

  # takes peps and a peptide_precision_hash.  Returns a hash with the same
  # keys of peptide_precision_hash where the value is a hash with these keys:
  #   :worst => worstcase protein precision
  #   :normal => estimaton by binomial/gaussian method (optimistic)
  #   :normal_stdev => the stdev of the normal method
  def peptide_precision_to_protein_precision(protein_validator, peps, peptide_precision_array, round_num_false=:ceil)
    peptide_precision_array.map do |precision|
      num_false = ((1.0 - precision) * peps.size).ceil
      reply = protein_validator.prothit_precision(peps, num_false)
      hash = {}
      %w(worst normal normal_stdev).zip(reply) do |label, answer|
        hash[label.to_sym] = answer
      end
      hash
    end
  end

  # takes an array of validator objects and peps (already separated out from
  # decoys; the decoy's can be passed in
  # returns an array of results
  def get_pephit_precision(validators, peps, decoy_peps=nil, grant_transmem_status=false)
    validators.map do |validator|
      if validator.class == Validator::Decoy
        validator.pephit_precision(peps, decoy_peps)
      else
        validator.pephit_precision(peps)
      end
    end
  end
end

class SpecID::Precision::Filter::Peps < Filter

  # can pass in the method to call.  If you have static options and you will
  # reuse your filter, you can pass them in here.
  # BEWARE: this will override any passed into the method at filter time.
  # If you need to do that, make a new, blank filter and pass in your args
  # at filter time
  def initialize(meth=nil, *opts)
    @method = meth
    if opts.size > 0
      @opts = opts
    else
      @opts = nil
    end
  end

  # passes the top peptide hits per attributes that it is hashed by
  # all hits with same score as top score are returned
  # assumes that all attributes are cast properly: Float,Integer, etc
  # converts xcorr, deltacn, deltamass, mass, and charge into numerical types
  # deletes the protein array (but not relevant proteins)
  # hashes on [pep.basename, pep.first_scan.to_i, pep.charge.to_i]
  # returns self for chaining
  # opts 
  #   :per => Array of attributes e.g. [:first_scan, :charge]   # TODO: allow lambda
  #   :by  => an array for sort_by_attributes 
  #           e.g. [:xcorr, :deltacn, :ppm, {:down => [:xcorr, :deltacn]}]
  #   :ties => *false | true | :as_array
  #             false -     one top hit is selected by random (by sorting)
  #             true  -     all ties are included in final answer
  #             :as_array - ties are included as an array 
  def top_hit(peps, opts = {})

    # get the top peptide by firstscan/charge (equivalent to .out files)
    top_peps = []
    #hash = peps.hash_by(*(opts[:per]))
    per_array = opts[:per]
    hash = peps.hash_by(*per_array)
    ties = opts[:ties]
    if ties == :as_array
      as_array = true
    end
    hash.values.each do |v|
      best_to_worst = v.sort_by_attributes(*(opts[:by]))
      if ties

        best_hit = best_to_worst.first
        ## get the values that matter for the top hit 
        # here get the attributes we are considering
        atts =
          if opts[:by].last.is_a? Hash
            opts[:by][0...-1]
          else
            opts[:by].dup
          end
        # find the best hits values
        top_hit_vals = atts.map do |att| 
          best_hit.send(att)        
        end

        tying_peps = []
        best_to_worst.each do |pep|
          tie = true
          atts.each_with_index do |att,i|
            unless (pep.send(att) == top_hit_vals[i])
              tie = false
              break 
            end
          end
          if tie
            tying_peps << pep
          else
            break
          end
        end
        if as_array
          if tying_peps.size == 1
            top_peps.push( *tying_peps )
          else
            top_peps.push( tying_peps )
          end
        else
          top_peps.push( *tying_peps )
        end
      else
        top_peps << best_to_worst.first
      end
    end
    top_peps
  end

  # returns self for chaining
  # ( >= +3 charge for the x3)
  def standard_sequest_filter(peps, x1,x2,x3,deltacn,ppm,include_deltacnstar=true)
    peps.select do |pep|
      pep_deltacn = pep.deltacn
      pep_charge = pep.charge

      ## The outer parentheses are critical to getting the correct answer!
      _passing = ( (pep_deltacn >= deltacn) and ((pep_charge == 1 && pep.xcorr >= x1) or (pep_charge == 2 && pep.xcorr >= x2) or (pep_charge >= 3 && pep.xcorr >= x3)) and ( pep.ppm <= ppm ))

      if _passing
        if ((!include_deltacnstar) && (pep_deltacn > 1.0))
          false
        else
          true
        end
      else
        false
      end
    end
  end

end

