require 'validator'

class Validator::Decoy < Validator
  include Precision::Calculator::Decoy

  # a Regexp (if concatenated) or a String (the filename of separate run)
  attr_accessor :constraint

  attr_accessor :decoy_on_match
  attr_accessor :correct_wins
  attr_accessor :decoy_to_target_ratio

  attr_accessor :last_pep_was_decoy

  attr_accessor :increment_normal
  attr_accessor :increment_decoy
  attr_accessor :increment_total_submitted

  attr_reader :normal_peps_just_submitted

  DEFAULTS = {
    :decoy_on_match => true,
    :correct_wins => true,
    :decoy_to_target_ratio => 1.0,
  }

  def initialize(opts={})
    merged = DEFAULTS.merge(opts)
    @constraint, @decoy_on_match, @correct_wins, @decoy_to_target_ratio = merged.values_at(:constraint, :decoy_on_match, :correct_wins, :decoy_to_target_ratio)
  end

  # returns [normal, decoy] (?? I think ??)
  # reads the full protein reference
  def partition(peps)
    if @decoy_on_match 
      if @correct_wins
        peps.partition do |pep|
          !(pep.prots.all? {|prot| prot.reference.match(@constraint) })
        end
      else  # fp wins
        peps.partition do |pep|
          !(pep.prots.any? {|prot| prot.reference.match(@constraint) })
        end
      end
    else 
      if @correct_wins
        peps.partition do |pep|
          pep.prots.any? {|prot| prot.reference.match(@constraint) }
        end
      else
        peps.partition do |pep|
          pep.prots.all? {|prot| prot.reference.match(@constraint) }
        end
      end
    end
  end

  def initialize_increment
    @increment_normal = 0
    @increment_decoy = 0
    @increment_total_submitted = 0
    @increment_initialized = true
  end


  # does not deal in separate_peps right now!!
  # will take an array or single peptide
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
    (normal, decoy) = partition(to_submit)
    @normal_peps_just_submitted = normal
    @increment_normal += normal.size
    @increment_decoy += decoy.size
    calc_precision(@increment_normal, @increment_decoy, @decoy_to_target_ratio)
  end

  def pephit_precision(peps, separate_peps=nil)
    if separate_peps
      calc_precision(peps.size, separate_peps.size, @decoy_to_target_ratio)
    else
      (norm, decoy) = partition(peps)
      calc_precision(norm.size, decoy.size, @decoy_to_target_ratio)
    end
  end

  def to_param_string
    "decoy="+ ["{constraint=#{(constraint ? constraint.inspect : '')}", "decoy_on_match=#{@decoy_on_match}", "correct_wins=#{@correct_wins}}"].join(", ")
  end
end


