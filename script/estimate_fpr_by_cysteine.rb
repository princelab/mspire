#!/usr/bin/ruby -w

## The yeast Scal db mean background is: 0.00984
## The yeast Cysteine background freq is: 0.0131986582396467
pep_seq_re = /<search_hit .* peptide="(\w+)"/o
pep_prob_re = /<peptideprophet_result probability="([\w\.]+)"/o

if ARGV.size != 3
  puts "usage #{File.basename(__FILE__)} cysteine_background_freq existing_freq peptide_prophet.xml"
  puts "  outputs (tab delimited): num_peptides, prob, fpr, cys_estimated_fpr"
  abort
end

def plot(base_toplot, base, title, xaxis, yaxis, hash, cats)
  File.open(base_toplot, "w") do |fh|
    fh.puts 'XYData'
    fh.puts base
    fh.puts title
    fh.puts xaxis
    fh.puts yaxis
    cats.each do |ar|
      fh.puts ar.join(" & ")
      ar.each do |a|
        fh.puts hash[a].join(" ")
      end
    end
  end
end

  ############################################################################
#### DO NOT MODIFY THIS GUY!  HE IS TAKEN FROM bin/filter_spec_id.rb
#### CHANGE HIM THERE (eventually we need to put him in a lib file)
# (actual # with cys, expected # with cys, total#peptides,
# mean_fraction_of_cysteines_true, std)
# PepHit(C) = Peptide containing cysteine
#   # Total PepHit(C)                   # Observed Bad Pep (C)
#   ------------------ proportional_to  ---------------------- 
#   # Total PepHit                      # Total Bad PepHit (X)
def fpr_by_cysteines(ac_num_with_cys, exp_num_with_cys, total_peptides, mean_fraction_true_cys=nil, std_fraction_true_cys=nil) 

  # the number of bona fide BAD cysteine hits
  # (some of the cysteine hits (~5%) are true positives)

  ac_num_with_cys -= exp_num_with_cys * mean_fraction_true_cys if mean_fraction_true_cys
  if ac_num_with_cys < 0.0 ; ac_num_with_cys = 0.0 end
  total_number_false = (ac_num_with_cys * total_peptides).to_f/exp_num_with_cys
  fpr = total_number_false / total_peptides
  [fpr, total_number_false]
end
############################################################################




(cysteine_background_freq, background_freq, file) = ARGV
cysteine_background_freq = cysteine_background_freq.to_f
background_freq = background_freq.to_f

seq_probs = []
last_seq_prob = nil
File.open(file) do |fh|
  fh.each do |line|
    if line =~ pep_seq_re
      ar = Array.new(2)
      ar[0] = $1
      seq_probs << ar
      last_seq_prob = ar
    elsif line =~ pep_prob_re
      last_seq_prob[1] = $1.to_f
    end
  end
end

#seq_probs.each do |seq|
#  if seq[0] !~ /\w/ || !seq[1].is_a?(Float)
#    abort "BAD PARSING!!"
#  end
#end
amino_acid_as_st = 'C'

sorted = seq_probs.sort_by {|v| v[1] }.reverse

## traverse the peptides
actual_cys_containing_peps = 0
expected_cys_containing_peps = 0.0
current_sum_one_minus_prob = 0.0
prob_estimated_fpr = 0.0
pep_cnt = 0
one_minus_freq = 1.0 - cysteine_background_freq

## tabulate:
pep_cnts = []
probs = []
prob_fprs = []
prob_tps = []
cys_fprs = []
cys_tps = []
fpr_diff = []


sorted.each do |ar|
  pep_cnt += 1

  pep = ar[0]
  prob = ar[1]

  ## Cysteine FPR: ##
  # Expected:
  expected_cys_containing_peps += (1.0 - (one_minus_freq**pep.size))
  # Actual:
  if pep.include?(amino_acid_as_st)
    actual_cys_containing_peps += 1
  end
  (cys_fpr, total_num_false_by_cys) = fpr_by_cysteines(actual_cys_containing_peps, expected_cys_containing_peps, pep_cnt, background_freq)
  cys_tp = pep_cnt.to_f - total_num_false_by_cys


  ## FPR by prob: ##
  # SUM(1-probX)/#peps
  current_sum_one_minus_prob += 1.0 - prob
  prob_estimated_fpr = current_sum_one_minus_prob / pep_cnt
  prob_tp = pep_cnt.to_f - current_sum_one_minus_prob

  ## GRAB or report the data:
  pep_cnts << pep_cnt
  probs << prob
  prob_fprs << prob_estimated_fpr
  prob_tps << prob_tp
  cys_fprs << cys_fpr
  cys_tps << cys_tp
  fpr_diff << prob_estimated_fpr - cys_fpr

  #puts [pep_cnt, prob, prob_estimated_fpr, cys_fpr].join("\t") 
end

hash = {
  'pep_cnts' => pep_cnts,
  'probs' => probs,
  'prob_fprs' => prob_fprs,
  'prob_tps' => prob_tps,
  'cys_fprs' => cys_fprs,
  'cys_tps' => cys_tps,
  'fpr_diff' => fpr_diff,
}


real_base = file.sub(/\.xml/,'')



## TPS vs FPR
base = real_base.dup
base << "." << "tps_vs_fpr"
base_toplot = base + '.to_plot'
title = "Peptide Prophet FPR Estimation (bg: #{background_freq})"
xaxis = "TPs"
yaxis = "FPR"
cats = [['prob_tps', 'prob_fprs'],['cys_tps', 'cys_fprs']]
plot(base_toplot, base, title, xaxis, yaxis, hash, cats)

## PEPHITS vs FPR
base = real_base.dup
base << "." << "num_pep_hits_vs_fpr"
base_toplot = base + '.to_plot'
title = "Peptide Prophet FPR Estimation (bg: #{background_freq})"
xaxis = "num peptide hits"
yaxis = "FPR"
cats = [['pep_cnts', 'prob_fprs'],['pep_cnts', 'cys_fprs']]
plot(base_toplot, base, title, xaxis, yaxis, hash, cats)

## PEPHITS VS FPR DIFF
base = real_base.dup
base << "." << "num_pep_hits_vs_fpr_diff"
base_toplot = base + '.to_plot'
title = "num_pep_hits vs fpr_diff (prob - cysteine) (bg: #{background_freq})"
xaxis = "num peptide hits"
yaxis = "FPR diff (prob - cysteine)"
cats = [['pep_cnts', 'fpr_diff']]
plot(base_toplot, base, title, xaxis, yaxis, hash, cats)

## PROB VS FPR DIFF
base = real_base.dup
base << "." << "prob_vs_fpr_diff"
base_toplot = base + '.to_plot'
title = "peptide prob vs fpr_diff (prob - cysteine) (bg: #{background_freq})"
xaxis = "peptide probability"
yaxis = "FPR diff (prob - cysteine)"
cats = [['probs', 'fpr_diff']]
plot(base_toplot, base, title, xaxis, yaxis, hash, cats)



=begin

returns [number_of_prots, actual_fpr]
def num_prots_above_fpr(prots, desired_fpr)
  current_fpr_rate_percent = 0.0
  previous_fpr_rate_percent = 0.0
  current_sum_one_minus_prob = 0.0
  proteins_within_fpr = 0
  actual_fpr = nil
  already_found = false
  prot_cnt = 0
  prots.each do |prot|
    prot_cnt += 1
    # SUM(1-probX)/#prots
    current_sum_one_minus_prob += 1.0 - prot._probability.to_f
    current_fpr_rate_percent = (current_sum_one_minus_prob / prot_cnt) * 100

    if current_fpr_rate_percent > desired_fpr && !already_found
      actual_fpr = previous_fpr_rate_percent
      proteins_within_fpr = prot_cnt
      already_found = true
    end
    previous_fpr_rate_percent = current_fpr_rate_percent
  end
  [proteins_within_fpr, actual_fpr]
end

=end






