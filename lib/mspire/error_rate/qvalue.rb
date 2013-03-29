require 'set'
require 'mspire/error_rate/decoy'

module Mspire

  module ErrorRate
    # For generating and working with q-value calculations.  The q-value is the global false discovery rate when accepting that particular ID.  We do not necessarily distinguish here between *how* the FDR is generated (i.e., Storey's pFDR "the occurrence of false positives" vs. Benjamini-Hochberg's FDR "the rate of false positives" [except to prefer Storey when possible] ).  The main point is that we sort and threshold based on a global FDR.
    module Qvalue
      module_function
         
      # returns a parallel array to target hits with qvalues
      # opts = :z_together true/false (default false) group all charges
      # together.
      # the sort block should sort from worst to best
      # by default, sorting is: {|hit| hit.score} if not provided
      # options also passed through to mixed_target_decoy
      def target_decoy_qvalues(target_hits, decoy_hits, opts={}, &sorting)
        sorting ||= :score
        opts = {:z_together => false}.merge(opts)
        target_set = Set.new(target_hits)

        # Proc.new doesn't do arity checking
        hit_with_qvalue_pairs = Proc.new do |hits|
          sorted_best_to_worst = (hits.sort_by(&sorting)).reverse
          (sorted_target_hits, qvalues) = Mspire::ErrorRate::Qvalue.mixed_target_decoy(sorted_best_to_worst, target_set, opts)
          sorted_target_hits.zip(qvalues)
        end

        all_together = target_hits + decoy_hits
        if !opts[:z_together]
          hit_with_qvalue_pairs.call(all_together)
        else
          all_hits = []
          by_charge = all_together.group_by(&:charge)
          by_charge.each do |charge,hits|
            all_hits.push(*(hit_with_qvalue_pairs.call(hits)))
          end
          all_hits
        end
      end

      # returns [target_hits, qvalues] (parallel arrays sorted from best hit to
      # worst hit).  expects an array-like object of hits sorted from best to worst
      # hit with decoys interspersed and a target_setlike object that responds to
      # :include? for the hit object assumes the hit is a decoy if not found
      # in the target set!  if monotonic is false, then the guarantee that
      # qvalues be monotonically increasing is not respected.
      def mixed_target_decoy(best_to_worst, target_setlike, opts={})
        opts = {:monotonic => true}.merge(opts)
        num_target = 0 ; num_decoy = 0
        monotonic = opts[:monotonic]
        sorted_target_hits = []
        qvalues = []
        best_to_worst.each do |hit|
          if target_setlike.include?(hit) 
            num_target += 1
            precision = Mspire::ErrorRate::Decoy.precision(num_target, num_decoy)
            sorted_target_hits << hit
            qvalues << (1.0 - precision)
          else
            num_decoy += 1
          end
        end
        if opts[:monotonic]
          min_qvalue = qvalues.last 
          qvalues = qvalues.reverse.map do |val| # from worst to best score
            if min_qvalue < val 
              min_qvalue
            else
              min_qvalue = val
              val
            end
          end.reverse
        end
        [sorted_target_hits, qvalues]
      end


    end
  end
end
