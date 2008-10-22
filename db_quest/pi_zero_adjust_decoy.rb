#!/usr/bin/ruby

require 'yaml'
require 'pi_zero'

# implements a reader of the combined interface:

file = ARGV.shift
unless file
  abort "need a combined.yaml type file"
end

yml = YAML.load_file file
yml.each do |filename,cats_hash|
  pr_decoy = cats_hash['estimates']['decoy']
  num_hits = pr_decoy['x']
  precision_ar = pr_decoy['y']
  #frit = PiZero.frit_from_precision(num_hits, precision_ar)
  #adjusted_precisions = precision_ar.map do |precision|
  #  adjusted_fir = frit * (1.0 - precision)
  #  1.0 - adjusted_fir
  #end
  max_num_corr_hits = 0
  ffrit = nil
  num_hits.zip(precision_ar).each do |nh, pr|
    num_correct_hits = pr * nh
    if num_correct_hits > max_num_corr_hits
      max_num_corr_hits = num_correct_hits
      ffrit = (nh.to_f - num_correct_hits) / nh
    end
  end
  p filename
  p max_num_corr_hits
  p ffrit
  #p num_hits
  #p precision_ar
  #p adjusted_precisions
end

