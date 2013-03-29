#require 'set'
#require 'mspire/ident/protein_group'

module Mspire
  module Quant
    module SpectralCounts
      Counts = Struct.new(:spectral, :aaseqcharge, :aaseq)
      class Counts
        def initialize(*args)
          super(*args)
          # default is zero counts
          self[0] ||= 0.0 ; self[1] ||= 0.0 ; self[2] ||= 0.0
        end
      end

      # returns a parallel array of Count objects.  If split_hits then counts
      # are split between groups sharing the hit.  peptide_hits must respond
      # to :charge and :aaseq.  If a block is given, the weight of a
      # particular hit can be given (typically this will be 1/#proteins
      # sharing the hit
      def self.counts(peptide_hits, &share_the_pephit)
        uniq_aaseq = {}
        uniq_aaseq_charge = {}
        weights = peptide_hits.map do |hit|
          weight = share_the_pephit ? share_the_pephit.call(hit) : 1
          # these guys will end up clobbering themselves, but the
          # linked_to_size should be consistent if the key is the same
          uniq_aaseq_charge[[hit.aaseq, hit.charge]] = weight
          uniq_aaseq[hit.aaseq] = weight
          weight
        end
        counts_data = [weights, uniq_aaseq_charge.values, uniq_aaseq.values].map do |array|
          array.reduce(:+)
        end
        Counts.new(*counts_data)
      end
    end
  end
end



