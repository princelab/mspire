

# from percolator
# This is a trivial class (since q-values are so straightforward with regards
# to precision), but it allows us to work with q-values using the same
# interface as all other validators
class Validator::QValue

  # objs should respond_to :q_value
  # q-values: 0.0 means no false discoveries, 0.5 means 50% false discoveries
  # 1 - (the largest q value) is the precision
  def precision(objs)
    return 1.0 if objs.size == 0
    largest_q_value = objs.map {|v| v.q_value }.max
    prec = 1.0 - largest_q_value
  end


  # objs should respond_to :q_value
  # These should be added from low q-value to high q-value
  # The last q-value added determines the precision
  def increment_precision(objs)
    if objs.is_a?(SpecID::Pep) or objs.is_a?(SpecID::Prot)
      objs = [objs]
    end
    precision(objs)
  end

  alias_method :pephit_precision, :precision
  alias_method :prothit_precision, :precision
  alias_method :increment_pephits_precision, :increment_precision
end
