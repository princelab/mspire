require 'validator'
require 'fasta'
require 'spec_id/sequest/params'

# objects of this class can calculate pephit_precision given an array of
# SpecID::Pep objects using the pephit_precision method.
class Validator::DigestionBased < Validator
  DEFAULTS = {
    #:false_to_total_ratio => 1.0,  # disable because this needs to be set
    # explicitly
    :background => 0.0,
  }

  # the number of tps
  attr_accessor :increment_tps
  # the number of fps
  attr_accessor :increment_fps

  # the total peptides submitted to the validator (regardless of tp, fp, or
  # nil)
  attr_accessor :increment_total_submitted

  # the ratio of false hits to total peptides in the fasta file
  attr_accessor :false_to_total_ratio

  # the false_to_total_ratio calculated (but not applied)
  attr_reader :calculated_background

  # For a sample with no false hits in it, (under defaults) this is the
  # fraction of peptides with the constraint over the total number of peptides
  # from which these hits are derived.
  attr_accessor :background


  # expects that classes define a partition method, and a @background
  def pephit_precision(peps)
    ## this gives us the fraction that are transmembrane (under defaults):
    (tps, fps) = partition(peps)
    (num_tps, num_fps) = calc_precision_prep(tps.size, fps.size)
    calc_precision(num_tps, num_fps)
  end

  # returns [num_tps, num_fps]
  def calc_precision_prep(num_tps, num_fps)
    total_peps_passing_partition = num_tps + num_fps
    num_fps = adjust_fps_for_background(num_tps, num_fps, background)
    ## we must use the false_to_total_ratio to estimate how many are really
    ## incorrect!
    # FALSE/TOTAL  = FALSE(found)/TOTAL(found)
    # TOTAL(found) = FALSE(found) * TOTAL/FALSE
    #              = FALSE(found) / (FALSE/TOTAL)
    total_false = num_fps / false_to_total_ratio
    # NOTE: the partition algorithm drops peptides that are transmembrane
    # under certain options.  Thus, the total false estimate must be tempered
    # by this lower number of total peptides.
    adjusted_tps = total_peps_passing_partition.to_f - total_false
    [adjusted_tps, total_false]
  end

  # returns self
  # assumes partition returns (tps, fps)
  def set_false_to_total_ratio(peps)
    (tps, fps) = partition(peps)
    self.false_to_total_ratio = fps.size.to_f / (tps.size + fps.size) 
    self
  end

end


