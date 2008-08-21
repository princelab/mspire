require 'validator/aa'


class Validator ; end
class Validator::AA ; end

# A class that uses the peps given to it and a background frequency to
# calculate the false_to_total_ratio at each turn.
class Validator::AAEst < Validator::AA
  attr_accessor :constraint
  attr_accessor :false_if_found

  # the frequency of the amino acid is used to estimate the false to
  # total ratio based on the pephits given for pephit_precision.
  # see Validator::AA.calc_frequency to calculate a frequency
  # or use set_frequency to set from pep hits.
  attr_accessor :frequency

  DEFAULTS = {
    :false_if_found => true
  }.merge(Validator::DigestionBased::DEFAULTS)  # background 0.0

  # only takes a string right now for constraint
  def initialize(constraint, options={})
    @constraint = constraint.to_s
    opts = DEFAULTS.merge(options)
    (@frequency, @false_if_found, @background) = opts.values_at(:frequency, :false_if_found, :background)
  end

  def pephit_precision(peps)
    set_false_to_total_ratio(peps)
    super(peps)
  end

  def set_false_to_total_ratio(peps)
    if peps.size > 0
      expected = 0.0
      peps.each do |pep|
        expected += (1.0 - ((1.0 - @frequency)**pep.aaseq.size))
      end
      @false_to_total_ratio = expected / peps.size
    else
      @false_to_total_ratio = 1.0
    end
  end

  def set_ongoing_false_to_total_ratio(peps)
    if peps.size > 0
      peps.each do |pep|
        @expected += (1.0 - ((1.0-@frequency)**pep.aaseq.size))
      end
      # @increment_total_submitted should == @increment_tps and @increment_fps
      # since these are either/or
      @false_to_total_ratio = @expected / @increment_total_submitted
    else
      @false_to_total_ratio = 1.0
    end
  end


  def to_param_string
    "aminoacid(bad_aa)=" + ["{constraint=#{@constraint}", "frequency=#{@frequency}", "bkg=#{(@background ? @background : 0.0) }}"].join(", ")
  end

  # takes objects responding to aaseq and sets the frequency based on
  # constraint.  constraint is one acceptable to initialize!  returns self
  def set_frequency(objs)
    table = SpecID::AAFreqs.new.calculate_frequencies(objs)
    @frequency = table[@constraint.to_sym]
    self
  end

   # if adding pephits in groups at a time, the entire group does not need to be
  # queried, just the individual hit.  Use this OR pephits_precision (NOT
  # both).  The initial query to this method will begin a running tally that
  # is saved by the validator.
  # takes either an array or a single pephit (determined by if it is a
  # SpecID::Pep)
  def increment_pephits_precision(peps)
    tmp = $VERBOSE; $VERBOSE = nil
    unless @increment_initialized
      initialize_increment
      @expected = 0.0
    end
    $VERBOSE = tmp

    to_submit = 
      if peps.is_a? SpecID::Pep
        [peps]
      else
        peps
      end
    @increment_total_submitted += to_submit.size
    (tps, fps) = partition(to_submit)
    #### THIS IS THE MAGIC FOR THIS VALIDATOR:
    set_ongoing_false_to_total_ratio(to_submit)
    
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



end
