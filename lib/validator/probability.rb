
# calculates precision based on the Benjamini-Hochberg FDR method.
# @TODO: class should probably be renamed to reflect method used!
# or options given to specify different methods (i.e., q-value)??
class Validator::Probability

  attr_accessor :prob_method

  def initialize(prob_method=:probability)
    @prob_method = prob_method
  end

  # objs should respond_to probability
  def precision(objs)
    return 1.0 if objs.size == 0

    current_sum_one_minus_prob = 0.0

    # this should work!
    #objs.inject(0.0) {|sum,obj| sum + (1.0 - obj.probability) }

    objs.each do |obj|
      # SUM(1-probX)/#objs
      current_sum_one_minus_prob += 1.0 - obj.send(@prob_method)
    end
    prec = 1.0 - (current_sum_one_minus_prob / objs.size)
  end


  # objs should respond_to probability
  # These should be added from high probability(1.0) to low (0.0)
  def increment_precision(objs)
    if objs.is_a?(SpecID::Pep) or objs.is_a?(SpecID::Prot)
      objs = [objs]
    end

    @total_objs ||= 0
    @current_sum_one_minus_prob ||= 0.0

    @total_objs += objs.size
    objs.each do |obj|
      @current_sum_one_minus_prob += 1.0 - obj.send(@prob_method)
    end
    prec = 1.0 - (@current_sum_one_minus_prob / @total_objs)
  end


  alias_method :pephit_precision, :precision
  alias_method :prothit_precision, :precision
  alias_method :increment_pephits_precision, :increment_precision
end
