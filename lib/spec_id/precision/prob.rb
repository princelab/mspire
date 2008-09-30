# note that we require  'spec_id/precision/prob/cmdline' below!

require 'spec_id/precision/prob/output'

module SpecID ; end
module SpecID::Precision ; end


# for probability based spec identifications (true probabilities, not the
# bioworks p-value (which they call probability)).
class SpecID::Precision::Prob

  PN_DEFAULTS = {
    :proteins => false,
    :validators => [],
    :sort_by_init => false,
  }

  require 'spec_id/precision/prob/cmdline'

  def precision_vs_num_hits_cmdline(args) 
    (spec_id_obj, options, option_parser) = CmdlineParser.new.parse(args)
    if spec_id_obj == nil
      puts option_parser
      return
    end
    final_answer = SpecID::Precision::Prob.new.precision_vs_num_hits(spec_id_obj, options)
    options[:output].each do |output|
      output[1] = $stdout unless output[1]
      SpecID::Precision::Prob::Output.new(*output).print(final_answer).close
    end
  end

  # this is the way I was doing it:
  #       ajdusted = (1+R)*prec / (R*precision +1) 
  #       # where R is the decoy_to_target ratio

  # opts may include:
  #   :proteins => true|*false
  #   :validators => array of Validator objects
  #
  #   This method will adjust the precision in the *probability* validators
  #   used in the decoy validator (both terms with pi_0 in the denominator go
  #   to zero if there is no decoy validator and the precision is not
  #   adjusted)
  #
  #       ajdusted = (1+(1/pi_0))*prec / ((precision/pi_0) +1) 
  #       # where pi_0 is the ratio incorrect target hits to total decoy hits
  #
  #   NOTE: if you have decoy data, you MUST pass in a decoy validator for the
  #   decoy pephits to be removed from other validator analyses!  
  #   
  # returns a hash of data
  #   :pephits_precision => [{validator => <name>, values => [<precision>,...]},... ]
  #   :params => :validators => [array of validators] (includes
  #   :calculated_backgrounds)
  #   :aaseqs => array of aaseqs
  #   :charges => array of charge
  #   :modified_peptides => array of modified sequence (only included if
  #   applicable)
  #
  # NOTE: For protein prophet, the results are given on a peptide+charge
  # basis.  
  #   
  # TODO: implement tihs guy:
  #   prothits_precision => {validator => <name>, values => {worst => ,
  #   normal, normal_stdev } }
  def precision_vs_num_hits(spec_id, opts={})
   
    opt = PN_DEFAULTS.merge(opts)

    out = {}
    num_pephits = []  # NOTE!: these are aaseq/aaseq_mod + charge for Prophet 
    val_hash = Hash.new {|hash,key| hash[key] = [] }
    val_calc_bkg_hash = Hash.new {|hash,key| hash[key] = [] }
    pepstrings = []
    modified_peptides = []
    pepcharges = []
    probabilities = []
    found_modified_peptide = false

    check_precisions = []
    check_precisions_decoy = []

    # do we need to deal with decoy peptides? (true/false)
    validators = opt[:validators].map
    decoy_vals = validators.select {|val| val.class == Validator::Decoy }
    

    if decoy_vals.size > 1
      raise(ArgumentError, "only one decoy validator allowed!") 
    else
      decoy_val = decoy_vals.first
      if decoy_val
        pi_zero = decoy_val.pi_zero
      end
    end

    validators.delete(decoy_val)
    other_validators = validators

    (probability_validators, other_validators) = other_validators.partition {|val| val.class == Validator::Probability }
    if opt[:initial_probability]
      probability_validators.each do |pv|
        pv.prob_method = :initial_probability
      end
    end

    n_count = 0
    d_count = 0


    # this is a peptide prophet
    is_peptide_prophet = 
      if spec_id.peps.first.respond_to?(:fval) ; true
      else ;false
      end

    use_q_value = other_validators.any? {|v| v.class == Validator::QValue }

    ## ORDER THE PEPTIDE HITS:
    ordered_peps = 
      if use_q_value
        spec_id.peps.sort_by {|v| v.q_value }
      elsif is_peptide_prophet
        spec_id.peps.reject {|v| v.probability == -1.0}.sort_by {|v| v.probability }.reverse
      else
        if opt[:sort_by_init]
          spec_id.peps.sort_by{|v| [v.initial_probability, v.n_instances,  ( v.is_nondegenerate_evidence ? 1 : 0 ), v.n_enzymatic_termini, ( v.is_contributing_evidence ? 1 : 0 ), v.n_sibling_peptides] }.reverse
        else
          spec_id.peps.sort_by{|v| [v.nsp_adjusted_probability, v.initial_probability, v.n_instances,  ( v.is_nondegenerate_evidence ? 1 : 0 ), v.n_enzymatic_termini, ( v.is_contributing_evidence ? 1 : 0 ), v.n_sibling_peptides] }.reverse
        end
      end

    # for probability based precision with decoy database (not using prophet's
    # -d flag) we do this:
    # foreach peptide.sorted_by_probability
    #   1. update the running precision of the validator REGARDLESS of
    #   decoy/target status of peptide. the internal hit counts are
    #   incremented.
    #   2. only increment reported HIT COUNTS on a non-decoy hit and record
    #   the precision as (1+R)*prec / (R*precision +1) where R is the ratio of
    #   decoy hits to target hits.  If it is 1:1 (R = 1) then this becomes:
    #   2*prec / (prec + 1)

    ## WORK THROUGH EACH PEPTIDE:
    ordered_peps.each_with_index do |pep,i|
      # probability validators must work on the entire set of normal and decoy

      last_prob_values = probability_validators.map do |val|
        reply = val.increment_pephits_precision(pep)
        check_precisions << reply
        reply
      end

      it_is_a_normal_pep = 
        if decoy_val
          # get the decoy precision
          decoy_precision = decoy_val.increment_pephits_precision(pep)

          # continue with ONLY normal peptides
          is_normal = (decoy_val.normal_peps_just_submitted.size > 0)
        else
          true
        end

      if it_is_a_normal_pep
        check_precisions_decoy << false
      else
        check_precisions_decoy << true
      end

      if it_is_a_normal_pep
        n_count += 1

        # UPDATE validators:
        val_hash[decoy_val].push(decoy_precision) if decoy_val
        probability_validators.zip(last_prob_values) do |val,prec| 
          if decoy_val
            raise ArgumentError, "pi_zero in decoy validator must not == 0" if pi_zero == 0
            val_hash[val].push( ((1.0/pi_zero+1.0)*prec) / ((prec/pi_zero) + 1.0) )
          else
            val_hash[val] << prec
          end
        end
        other_validators.each do |val|
          val_hash[val] << val.increment_pephits_precision(pep)
          if val.is_a? Validator::DigestionBased
            val_calc_bkg_hash[val] << val.calculated_background
          end
        end

        # UPDATE other basic useful information:
        if pep.respond_to?(:mod_info)
          modified_pep_string =
            if pep.mod_info
              found_modified_peptide = true
              pep.mod_info.modified_peptide
            else
              nil
            end
          modified_peptides << modified_pep_string
        else
          modified_pep_string =
            if pep.sequence =~ /[^A-Z\-\.]/
              found_modified_peptide = true
              pep.sequence
            else
              nil
            end
          modified_peptides << modified_pep_string
        end
        pepcharges << pep.charge 
        pepstrings << pep.aaseq
        probabilities << pep.probability  # this is the q_value if percolator
        num_pephits << (i+1)
      else
        d_count += 1
      end
    end
    if found_modified_peptide
      out[:modified_peptides] = modified_peptides
    end
    if use_q_value
      out[:q_values] = probabilities
    else
      out[:probabilities] = probabilities
    end
    out[:pephits] = ordered_peps  # just in case they want to see
    out[:count] = num_pephits
    out[:aaseqs] = pepstrings
    out[:charges] = pepcharges
    out[:pephits_precision] = opt[:validators].map do |val| 
      hsh = {}
      hsh[:validator] = Validator::Validator_to_string[val.class.to_s]
      hsh[:values] = val_hash[val]
      hsh
    end
    out[:params] = {}
    out[:params][:validators] = Validator.sensible_validator_hashes(opt[:validators]).zip(opt[:validators]).map do |hash,val|
      hash.delete(:calculated_background)
      hash[:calculated_backgrounds] = val_calc_bkg_hash[val]
      hash
    end
    out
  end
end


