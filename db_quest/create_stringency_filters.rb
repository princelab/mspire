#!/usr/bin/ruby

require 'generator'
require 'ostruct'

#######################################################
# there will be num_filters + 1
to_run = OpenStruct.new
to_run.all = false
to_run.rand = false
to_run.rand_tight = true
to_run.xcorr_dcn_ppm = false
#######################################################
#include_deltacnstar = ['t', 'f']
include_deltacnstar = ['t']
#postfilters = ['s', 'a', 'ac']
postfilters = ['s']
#######################################################
num_filters = 50
rand_num_filters = 999
#######  For high mass accuracy:
#$ppm_random_max = 20
#$ppm_random_max = 20
#$ppm_random_min = 6
$ppm_static = 25
#######  For low mass accuracy:
#$ppm_random_max = 1500
$ppm_random_max = 1500
$ppm_random_min = 800
#$ppm_static = 1000
#######################################################


def print_ars(ars, dcnstar, pf)
  SyncEnumerator.new(*ars).each do |row|
    full_row = row.dup
    if dcnstar
      full_row.push(dcnstar)
    end
    if pf
      full_row.push(pf)
    end
    puts full_row.join(' ')
  end
end

def print_hash(hash, order, dcnstar, pf)
  to_print = order.map do |key|
    hash[key]
  end
  print_ars(to_print, dcnstar, pf)
end

def random_between_start_stop_ar(ar, num_filters)

  largest = [ ar[1], ar[0]].max
  smallest = [ ar[1], ar[0]].min

  range = (ar[1].to_f - ar[0].to_f).abs
  # all of them include zero, so we can simply scale to the highest number
  # with no more thought
  (0..num_filters).to_a.map do |_|
    rnum = range * rand
    rnum += smallest
    if rnum > largest or rnum < smallest
      abort "NUMBER OUT OF RANGE!"
    end
    rnum
  end
end


# jointly expects an ar of ars that will then be constrained in that each
# later array in the ars will have a value greater than that in the preceding
def random_between_start_stop_ar_constrained(ar, num_filters, jointly=false)

  if jointly
    all_ars = []
    ar.each_with_index do |lil_ar,index|
      largest = [ lil_ar[1], lil_ar[0]].max
      smallest = [ lil_ar[1], lil_ar[0]].min

      range = (lil_ar[1].to_f - lil_ar[0].to_f).abs
      # all of them include zero, so we can simply scale to the highest number
      # with no more thought
      filters = []
      (0..num_filters).to_a.each do |i|
        rnum = nil
        loop do   # wait until this value is bigger than last columns val
          rnum = range * rand
          rnum += smallest
          break if ((index == 0) or (rnum >= all_ars[index-1][i]))
          if rnum > largest or rnum < smallest
            abort "NUMBER OUT OF RANGE!"
          end
        end
        filters << rnum
      end
      all_ars.push(filters)
    end
    all_ars
  else
    largest = [ ar[1], ar[0]].max
    smallest = [ ar[1], ar[0]].min

    range = (ar[1].to_f - ar[0].to_f).abs
    # all of them include zero, so we can simply scale to the highest number
    # with no more thought
    (0..num_filters).to_a.map do |_|
      rnum = range * rand
      rnum += smallest
      if rnum > largest or rnum < smallest
        abort "NUMBER OUT OF RANGE!"
      end
      rnum
    end
  end
end


def array_from_start_stop_ar(ar, num_filters)
  range = ar[1].to_f - ar[0]
  increment = range/num_filters
  start = ar[0].to_f
  changing = (0..num_filters).to_a.map do |factor|
    start + (factor*increment)
  end
end

def static_array(val, num_filters)
    (0..num_filters).to_a.map { val }
end

#ranged =  {
#  :x1 => [0,4.0],
#  :x2 => [0,5.0],
#  :x3 => [0,6.5],
##  :dcn => [0,0.8],
#  :ppm => [22,0],
#}
#

# ^ see original above
# THESe are just for random
ranged =  {
  :x1 => [0,4.0],
  :x2 => [0,5.0],
  :x3 => [0,6.5],
  :dcn => [0,0.8],
  :ppm => [$ppm_random_max,0],
}

ranged_tight =  {
  :x1 => [1.0,3.2],
  :x2 => [1.4,3.5],
  :x3 => [1.5,5.0],
  :dcn => [0,0.5],
  :ppm => [$ppm_random_min,$ppm_random_max],
}



static = {
  :x1 => 1.2,
  :x2 => 1.5,
  :x3 => 2.0,
  :dcn => 0.1,
  :ppm => $ppm_static,
}

#vals = x1, x2, x3, dcn, ppm]
order = %w(x1 x2 x3 dcn ppm).map {|v| v.to_sym }


pf = nil
dcnstar = nil

#include_deltacnstar.each do |dcnstar|
#  postfilters.each do |pf|

# filtering stringency (all):
if to_run.all
  ars = order.map do |pr|
    array_from_start_stop_ar(ranged[pr], num_filters)
  end
  print_ars(ars, dcnstar, pf)
end

# random (just added)
if to_run.rand
  srand 549
  ars = order.map do |pr|
    random_between_start_stop_ar(ranged[pr], rand_num_filters)
  end
  print_ars(ars, dcnstar, pf)
end

# random (just added)
if to_run.rand_tight
  srand 549
  together = ranged_tight.values_at(:x1, :x2, :x3)
  ars = random_between_start_stop_ar_constrained(together, rand_num_filters, true)
  ars.push( random_between_start_stop_ar_constrained(ranged_tight[:dcn], rand_num_filters) )
  ars.push( random_between_start_stop_ar_constrained(ranged_tight[:ppm], rand_num_filters) )
  print_ars(ars, dcnstar, pf)
end



# dcn and ppm
if to_run.xcorr_dcn_ppm
  [:dcn, :ppm].each do |var|
    to_print = {}
    to_print[var] = array_from_start_stop_ar(ranged[var], num_filters)

    others = order - [var]
    others.each do |var|
      to_print[var] = static_array(static[var], num_filters)
    end
    print_hash(to_print, order, dcnstar, pf)
  end

  # xcorrs together
  to_print = {}
  changing = [:x1, :x2, :x3].each do |var|
    to_print[var] = array_from_start_stop_ar(ranged[var], num_filters)
  end

  others = [:dcn, :ppm]
  static_guys = others.each do |var|
    to_print[var] = static_array(static[var], num_filters)
  end
  print_hash(to_print, order, dcnstar, pf)
end

#  end
#end
