require 'validator/digestion_based'
require 'fasta'
require 'spec_id/aa_freqs'

# Constraints on aaseq attribute of peptides (the bare amino acid sequence)
# works by calculating amino acid frequencies in the fasta file used.
class Validator::AA < Validator::DigestionBased
  include Precision::Calculator

  attr_accessor :constraint

  # it is a false hit if the amino acid is located in the peptide
  attr_accessor :false_if_found
 
  DEFAULTS = Validator::DigestionBased::DEFAULTS.merge( {
    :false_if_found => true,
  } )

  # returns tp, fp
  def partition(peps)
    (found, not_found) = peps.partition do |pep|
      pep.aaseq.include?(@constraint)
    end
    if @false_if_found
      [not_found, found] 
    else
      [found, not_found]
    end
  end

  # right now only accepts single amino acids as constraints (as a string,
  # e.g. 'C', or symbol, e.g. :C)
  # options:
  #  :false_to_total_ratio => if a true digestion was already performed (see
  #                           Validator::AA.calc_false_to_total_ratio)
  #  :false_if_found => it is a false positive if the amino acid is found.
  #  :background => the background level of amino acid Float
  def initialize(constraint, options={})
    @constraint = constraint.to_s
    opts = DEFAULTS.merge(options)
    (@false_to_total_ratio, @false_if_found, @background) = opts.values_at(:false_to_total_ratio, :false_if_found, :background)
  end

  def to_param_string
    "aminoacid(bad_aa)=" + ["{constraint=#{@constraint}", "false_to_total_ratio=#{@false_to_total_ratio}", "bkg=#{(@background ? @background : 0.0) }}"].join(", ")
  end
end

