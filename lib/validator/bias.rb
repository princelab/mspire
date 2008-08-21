require 'validator'
require 'validator/digestion_based'

# class for any generic kind of bias.  For instance, a list of high abundance
# proteins we would expect to see, or a list of low abundance proteins we
# would not expect to see, or proteins that have been filtered out in some
# way, etc.
class Validator::Bias < Validator::DigestionBased
  include Precision::Calculator

  # a fasta object (by default containing proteins expected to be in the
  # sample [see proteins_expected to modify that behavior])
  attr_reader :fasta

  # correct_wins means that only a single protein from a pep.aaseq must match
  # the fasta object for the pep hit to be considered valid.  Otherwise, all
  # must be a match (logic negated by proteins_expected)
  attr_accessor :correct_wins

  # proteins_expected==true means we expect to see the proteins in the sample
  # proteins_expected==false means we do not expect to see these proteins in
  # the sample
  attr_accessor :proteins_expected

  # a hash made by taking each fasta reference in fasta_object, (everything
  # until a space) and setting the value to true.  It can be queried with the
  # start of an fasta sequence
  attr_accessor :short_reference_hash

  DEFAULTS = Validator::DigestionBased::DEFAULTS.merge( {
    :proteins_expected => true, 
    :correct_wins => true,
  } )

  # options: 
  #   (t = true, f = false, '*'= default)
  #   :proteins_expected => *t/f  we expect to see the fasta proteins in our hit list
  #   :correct_wins => *t/f  a single peptide hit from one of these proteins
  #                    constitutes a true positive 
  #   :background => Float  (*0.0-1.0)
  #   :false_to_total_ratio => Float (*nil by default)
  def initialize(fasta_object, options={})
    opts = DEFAULTS.merge(options)
    (@proteins_expected, @correct_wins, @background, @false_to_total_ratio) = opts.values_at(:proteins_expected, :correct_wins, :background, :false_to_total_ratio)
    @fasta = fasta_object
    @header_split_hash = @fasta.prots.map {|prot| prot.reference }
    @short_reference_hash = self.class.make_short_reference_hash(fasta_object)
  end

  def self.make_short_reference_hash(fasta_object)
    hash = {}
    fasta_object.each do |prot|
      hash[prot.first_entry] = true
    end
    hash
  end

  def partition(peps)
    klass = self.class
    cw = 
      if !@proteins_expected
        !@correct_wins
      else
        @correct_wins
      end

    (tp, fp) = 
      if cw
        peps.partition do |pep|
          pep.prots.any? do |pepprot| 
            @short_reference_hash.key?( pepprot.first_entry )
          end
        end
      else
        peps.partition do |pep|
          pep.prots.any? do |pepprot| 
            !@short_reference_hash.key?( pepprot.first_entry )
          end
        end
      end

    if !@correct_wins
      tp, fp = fp, tp
    end

    [tp, fp]
  end

  # pephit_precision is done through inheritance

  def to_param_string
    "abundance=" +  ["{fasta=#{@fasta.filename}", "proteins_expected=#{@proteins_expected}", "correct_wins=#{@correct_wins}", "background=#{@background}}"].join(", ")
  end

end
