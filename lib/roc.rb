



# Class for all types of classification analysis:
# receiver-operator-characteristics, precision-recall, etc..  Some definitions
# from (Davis & Goadrich. Proceedings of the 23rd
# International Conference on Machine Learning, Pittsburgh, PA, 2006):
#   Recall              = TP/(TP+FN) [aka, Sensitivity]
#   Precision           = TP/(TP+FP) [aka, Positive Predictive Value]
#   True Positive Rate  = TP/(TP+FN)
#   False Positive Rate = FP/(FP+TN)
#
# Keys to some abbreviations used in this class:
#   pred = number predicted to be correct
#   tps = number of true positives
#   ppv = positive predictive value
#   om_ppv = one minus positive predictive value = FP/(TP+FP)
#
# NOTE: this class assumes that lower scores are better.  Negate your scores
# if this is not the case.
#
# For estimation of false positive rates using a decoy database strategy, see
# the DecoyROC class.
class ROC


  # returns area under the curve found by trapezoids
  # x and y specify the coordinates to use
  # x should be monotonic increasing
  def area_under_curve(x,y)
    area = 0.0
    (0...(x.size-1)).each do |i|
      # determine which is larger 
      if y[i+1] >= y[i]
        y1 = y[i+1]; y0 = y[i] 
      else
        y0 = y[i+1]; y1 = y[i] 
      end
      area += (x[i+1]-x[i]).to_f * ( y0.to_f + (y1-y0).to_f/2 ) 
    end
    area
  end

  # takes two lists of values and makes doublets [[val, boolean],...]
  def separate_to_doublets(tps, fps)
    true_doublets = tps.map {|v| [v, 0] }
    false_doublets = fps.map {|v| [v, 1] }
    all_doublets = true_doublets + false_doublets
    all_doublets.sort!
    all_doublets.map {|v| ((v[1] == 0) ? [v[0], true] : [v[0], false]) }
  end

  # given an array of doublets where each doublet is a value and a boolean,
  # sorts the list and divides it into two arrays (tps, fps) of the values.
  # The output can then be fed into many of the other routines.
  def doublets_to_separate(list)
    tp = []; fp = []
    list.each do |dbl|
      if dbl[1]
        tp << dbl
      else
        fp << dbl
      end
    end
    [tp,fp].collect do |arr|
      arr.collect! {|dbl| dbl[0] }
      arr.sort
    end
  end

  # Base function for tps calculations
  def tps_and_ppv(tp, fp)
    tp_i = 0
    fp_i = 0
    x = []
    y = []
    num_tps = 0

    while tp_i < tp.size
      while fp_i < fp.size && tp[tp_i] >= fp[fp_i]
        fp_i += 1
      end
      unless tp[tp_i] == tp[tp_i+1]
        # get the correct number of each
        num_tps = tp_i + 1 
        num_fps = fp_i 

        x << num_tps
        y << num_tps.to_f/(num_tps+num_fps)

      end
      tp_i += 1 
    end
    return x, y
  end

  # takes previously sorted doublets [value, boolean] 
  def numhits_and_ppv(doublets)
    x = []
    y = []
    tps = 0
    fps = 0
    doublets.each_with_index do |d,i|
      if d[1] ; tps += 1
      else ; fps += 1 end

      if (i+1 == doublets.size) || (d[0] != doublets[i+1][0])
        num_hits = tps + fps
        x << num_hits
        y <<  tps.to_f/num_hits
      end
    end
    [x, y]
  end


end

# For calculating precision given lists of hits and decoy hits.  The hits are
# assumed to have false positives within them that can be estimated from the
# number of decoy hits at the same rate
# NOTE: this class assumes that lower scores are better.  Negate your scores
# if this is not the case.
class DecoyROC < ROC

  # returns the [num_hits, num_tps, precision] as a function of true
  # positives.  Method will return precisely what is calculated (meaning some
  # answers may seem bizarre if you have better decoy hits than real).
  def pred_and_tps_and_ppv(hits, decoy_hits)
    hits_i = 0
    decoy_i = 0

    num_hits_ar = []
    num_tps_ar = []
    ppv_ar = []

    while hits_i < hits.size
      while decoy_i < decoy_hits.size && hits[hits_i] >= decoy_hits[decoy_i]
        decoy_i += 1
      end
      unless hits[hits_i] == hits[hits_i+1]
        ## determine the number of false positives
        tot_num_hits = hits_i+1
        num_tps = tot_num_hits - decoy_i

        num_hits_ar << tot_num_hits
        num_tps_ar << num_tps
        ppv_ar << ( num_tps.to_f/tot_num_hits )

      end
      hits_i += 1 
    end
    [num_hits_ar, num_tps_ar, ppv_ar]
  end

  # returns [num_hits, precision] as a function of num hits.  decoy hits are
  # seen merely as indicators of the number of false hits in the dataset.
  # This is the same algorithm as pred_and_tps_and_ppv, just eliminates
  # uneeded calcs
  def pred_and_ppv(hits, decoy_hits)
    hits_i = 0
    decoy_i = 0

    num_hits_ar = []
    ppv_ar = []

    while hits_i < hits.size
      while decoy_i < decoy_hits.size && hits[hits_i] >= decoy_hits[decoy_i]
        decoy_i += 1
      end
      unless hits[hits_i] == hits[hits_i+1]
        ## determine the number of false positives
        tot_num_hits = hits_i+1
        num_tps = tot_num_hits - decoy_i

        num_hits_ar << tot_num_hits
        ppv_ar << ( num_tps.to_f/tot_num_hits )

      end
      hits_i += 1 
    end
    [num_hits_ar, ppv_ar]

  end

end
