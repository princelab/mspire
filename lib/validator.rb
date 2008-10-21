
class Validator

  # in the absence of digestion, does the spec_id type requires pephits for
  # validation?
  def self.requires_pephits?(spec_id_obj)
    case spec_id_obj
    when Proph::ProtSummary : true
    when Proph::PepSummary : true
    when SQTGroup : true
    else ; false
    end
  end

  Validator_to_string = {
    'Validator::AA' => 'badAA',
    'Validator::AAEst' => 'badAAEst',
    'Validator::Decoy' => 'decoy',
    'Validator::Transmem::Protein' => 'tmm',
    'Validator::TruePos' => 'tps',
    'Validator::Bias' => 'bias',
    'Validator::Probability' => 'prob',
    'Validator::QValue' => 'qval',
    :bad_aa => 'badAA',
    :bad_aa_est => 'badAAEst',
    :decoy => 'decoy',
    :tmm => 'tmm',
    :tps => 'tps',
    :bias => 'bias',
    :prob => 'prob',
    :qval => 'qval',
  }

  def initialize_increment
    @increment_tps = 0
    @increment_fps = 0
    @increment_total_submitted = 0
    @increment_initialized = true
  end

  # if adding pephits in groups at a time, the entire group does not need to be
  # queried, just the individual hit.  Use this OR pephits_precision (NOT
  # both).  The initial query to this method will begin a running tally that
  # is saved by the validator.
  # takes either an array or a single pephit (determined by if it is a
  # SpecID::Pep)
  def increment_pephits_precision(peps)
    tmp = $VERBOSE; $VERBOSE = nil
    initialize_increment unless @increment_initialized
    $VERBOSE = tmp

    to_submit = 
      if peps.is_a? SpecID::Pep
        [peps]
      else
        peps
      end
    @increment_total_submitted += to_submit.size
    (tps, fps) = partition(to_submit)
    @increment_tps += tps.size
    @increment_fps += fps.size
    (num_tps, num_fps) = 
      if self.respond_to?(:calc_precision_prep)  # for digestion based validators
        (num_tps, num_fps) = calc_precision_prep(@increment_tps, @increment_fps)
        [num_tps, num_fps]
      else
        [@increment_tps, @increment_fps]
      end
    calc_precision(num_tps, num_fps)
  end


  # returns an adjusted false positive rate (a float not to drop below 0.0)
  # based on a background of 'false'-false positive hits to total hits.  Also
  # sets the @calculated_background attribute.  Accepts floats or ints
  def adjust_fps_for_background(num_tps, num_fps, background)
    num_fps = num_fps.to_f
    total_peps = num_tps + num_fps
    @calculated_background = num_fps / total_peps
    num_fps -= (total_peps.to_f * background)
    num_fps = 0.0 if num_fps < 0.0
    num_fps
  end

  # copied from libjtp: vec
  # returns the mean and std_dev
  def sample_stats(array)
    _len = array.size
    _sum = 0.0
    _sum_sq = 0.0
    array.each do |val|
      _sum += val
      _sum_sq += val * val
    end
    std_dev = _sum_sq - ((_sum * _sum)/_len)
    std_dev /= ( (_len > 1) ? (_len-1) : 1 )
    # on occasion, a very small negative number occurs
    if std_dev < 0.0    
      std_dev = 0.0 
    else
      std_dev = Math.sqrt(std_dev)
    end
    mean = _sum.to_f/_len
    [mean, std_dev]
  end

  # takes an array of validators and returns a fresh array where each has been
  # turned into a sensible hash (with symbols as the keys!)
  def self.sensible_validator_hashes(validators)
    validators.map do |val|
      hash = {}
      case val
      when Validator::TruePos
        hash.merge( {:correct_wins => val.correct_wins, :file => val.fasta.filename } )
      when Validator::AAEst
        %w(frequency background calculated_background).each do |cat|
          hash[cat.to_sym] = val.send(cat.to_sym)
        end
      when Validator::AA
        %w(false_to_total_ratio background calculated_background).each do |cat|
          hash[cat.to_sym] = val.send(cat.to_sym)
        end
      when Validator::Decoy
        %w(pi_zero correct_wins decoy_on_match).each do |cat|
          hash[cat.to_sym] = val.send(cat.to_sym)
        end
        hash[:constraint] = val.constraint.inspect if val.constraint
      when Validator::Bias
        %w(correct_wins proteins_expected background calculated_background false_to_total_ratio).each do |cat|
          hash[cat.to_sym] = val.send(cat.to_sym)
        end
        hash[:file] = val.fasta.filename
      when Validator::Transmem::Protein
        %w(false_to_total_ratio min_num_tms soluble_fraction correct_wins no_include_tm_peps background calculated_background transmem_file).each do |cat|
          hash[cat.to_sym] = val.send(cat.to_sym)
        end
      when Validator::Probability
        %w(prob_method).each do |cat|
          hash[cat.to_sym] = val.send(cat.to_sym)
        end
      when Validator::QValue
        # no params to add
      else ; raise ArgumentError, "Don't know the validator class #{val}"
      end
      klass_as_s = val.class.to_s
      hash[:type] = Validator_to_string[klass_as_s]
      hash[:class] = klass_as_s
      hash
    end
  end
end

module Precision::Calculator
  # calculates precision by the assumption that the first group are all true
  # hits and the second are all false hits
  # (0,0) is returned as 1.0
  def calc_precision(num_true_hits, num_false_hits)
    if ((num_true_hits.to_f == 0.0) && (num_false_hits.to_f == 0.0))
      1.0
    else
      num_true_hits.to_f / (num_true_hits.to_f + num_false_hits.to_f)
    end
  end
end

# will calculate precision for groups of proteins where the first group are
# normal hits (which may be true or false) and the second are decoy hits.
# edge case:  if num_normal.to_f == 0.0 then if num_decoy.to_f > 0 ; 0, else 1
module Precision::Calculator::Decoy
  def calc_precision(num_normal, num_decoy, frit=1.0)
    # will calculate as floats in case fractional amounts passed in for
    # whatever reason
    num_normal_f = num_normal.to_f
    num_true_pos = num_normal_f - (num_decoy.to_f * frit)
    precision =
      if num_normal_f == 0.0
        if num_decoy.to_f > 0.0
          0.0
        else
          1.0
        end
      else
        num_true_pos/num_normal_f
      end
  end
end

#require 'validator/true_pos'
#require 'validator/aa'
#require 'validator/aa_est'
#require 'validator/bias'
#require 'validator/decoy'
#require 'validator/transmem'
#require 'validator/probability'
#require 'validator/q_value'
#require 'validator/prot_from_pep'

