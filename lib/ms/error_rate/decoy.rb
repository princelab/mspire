
module MS
  module ErrorRate
    module Decoy
      module_function

      # this is the # true positives (found by estimating the number of false
      # hits using the # decoy)
      # pi_not is the ratio of decoy hits to the estimated false hits in the
      # target set.  A data set with a small fraction of true hits will have a
      # pi_not close to 1.  A data set where 40% of the hits are correct
      # should have a pi_not of 0.6.
      # For instance, Spivak uses a fixed pi_not of 0.9 in J. Proteome Res.,
      # 2009, 8 (7), pp 3737–3745
      def precision(num_target, num_decoy, pi_not=1.0)
        num_target_f = num_target.to_f
        num_true_pos = num_target_f - (num_decoy.to_f * pi_not)
        precision =
          if num_target_f == 0.0
            if num_decoy.to_f > 0.0
              0.0
            else
              1.0
            end
          else
            num_true_pos/num_target_f
          end
        precision
      end

      # the false positive predictive rate (sometimes called the false
      # positive rate).  This is 1 - precision
      def fppr(num_target, num_decoy, pi_not=1.0)
        1.0 - precision(num_target, num_decoy, pi_not=1.0)
      end

      extend(self)
    end
  end
end
