require 'validator'
require 'vec'
require 'enumerator'

class Validator ; end
class Validator::Background

  attr_accessor :data

  def initialize(data=nil)
    @data = data
  end

  def delete_nan!(vec)
    vec.each_with_index do |v,i|
      if v.nan?
        vec[i] = 0
      end
    end
  end

  def stdev_plus_spread(stdev_factor=2.0, stdev_points=15, min_window_pre=5, min_window_post=5)
    data_vec = VecD[*@data]
    delete_nan!(data_vec)
    stdev_transform = data_vec.transform(9) {|vec| (stdev_factor * vec.sample_stats[1]) + vec.spread  } 
    smoothed_stdev = stdev_transform.transform(9) {|vec| vec.avg }
    smoothed_stdev_derivs = smoothed_stdev.chim
    last_0_index = index_of_last_0(smoothed_stdev_derivs)
    min_in_window(data_vec, last_0_index, min_window_pre, min_window_post)
  end

  # not really working right currently
  def derivs(avg_points=15, min_window_pre=5, min_window_post=5)
    data_vec = VecD[*@data]
    delete_nan!(data_vec)
    drvs = data_vec.chim
    # absolute value
    drvs.each_with_index {|x,i| drvs[i] = x.abs }
    mv_avg = drvs.transform(avg_points) {|v| v.avg }
    last_0_index = index_of_last_0(mv_avg.chim)
    min_in_window(data_vec, last_0_index, min_window_pre, min_window_post)
  end

  def index_of_last_0(vec)
    last_0_index = nil
    vec.each_with_index do |v,i|
      if v == 0
        last_0_index = i
      end
    end
    last_0_index
  end

  # returns the minimum value in the window centered on index
  def min_in_window(vec, index, pre, post)
    last_index = vec.size - 1
    start = index - pre
    stop = index + post
    start = 0 if start < 0
    stop = last_index if stop > last_index
    vec[start..stop].min
  end

  # very simple, should work
  def min_mesa(start, stop, points=3)
    data_vec = VecD[*@data]
    delete_nan!(data_vec)
    smoothed = data_vec.transform(3) {|v| v.avg }
    smoothed[start..stop].min
  end
  
end

