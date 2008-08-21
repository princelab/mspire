require 'validator'

class Validator::TruePos < Validator
  include Precision::Calculator
  attr_reader :fasta
  attr_accessor :correct_wins

  # correct_wins means that only a single protein from a pep.aaseq must match
  # the fasta object for the pep hit to be considered valid.  Otherwise, all
  # must be a match
  def initialize(fasta_obj, correct_wins = true)
    @fasta = fasta_obj
    @fasta_headers = @fasta.prots.map {|prot| prot.header }
    @correct_wins = correct_wins
  end

  def partition(peps)
    if @correct_wins
      peps.partition do |pep|
        @fasta_headers.any? do |header| 
          pep.prots.any? do |pepprot| 
            header.include? pepprot.reference
          end
        end
      end
    else
      peps.partition do |pep|
        pep.prots.all? do |pepprot| 
          @fasta_headers.any? do |header| 
            header.include? pepprot.reference
          end
        end
      end
    end
  end

  def pephit_precision(peps)
    (tp, fp) = partition(peps)
    calc_precision(tp.size, fp.size)
  end

  def to_param_string
    "true_positives(tps)=" +  ["{fasta=#{@fasta.filename}", "correct_wins=#{@correct_wins}}"].join(", ")
  end

end
