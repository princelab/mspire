#!/usr/bin/ruby -w

require 'vec'

# FOR SCer yeast db the and orbi mudpit7 the mean_actual_vs_expected fraction
# is 0.0101409563168847

# <peptide peptide_sequence="IEAALSDALAALQIEDPSADELR" charge="3" initial_probability="1.00" nsp_adjusted_probability="1.00" ...

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
  system "plot.rb -w lp --eps_png --noenhanced #{base_toplot}"
end

peptide_re = /<peptide peptide_sequence="(\w+)" charge="\d" initial_probability="([\w\.]+)" nsp_adjusted_probability="([\w\.]+)"/o

unless ARGV.size == 2
  abort "usage: #{File.basename(__FILE__)} cysteine_background_freq <file>-prot.xml"
end

(cysteine_background_freq, file) = ARGV

# each pep = [nsp_prob, init_prob, SEQUENCE]
peps = []
File.open(file) do |fh|
  fh.each do |line|
    if line =~ peptide_re
      peps << [$3.to_f,$2.to_f,$1]
    end
  end
end


amino_acid_as_st = 'C'
one_minus_freq = 1.0 - cysteine_background_freq.to_f
actual_cys_containing_peps = 0
expected_cys_containing_peps = 0.0
current_sum_one_minus_prob = 0.0
prob_estimated_fpr = 0.0
pep_cnt = 0

the_probs = []
the_fractions = []
special_probs = []




#peps.sort.reverse.each do |ar|
#peps.sort.each do |ar|
peps.sort_by{|pep| (3.0*pep[0]) + pep[1]}.reverse.each do |ar|
  (nsp_prob, init_prob, pep) = ar
  ## Cysteine FPR: ##
  # Expected:
  expected_cys_containing_peps += (1.0 - (one_minus_freq**pep.size))
  # Actual:
  if pep.include?(amino_acid_as_st)
    actual_cys_containing_peps += 1
  end
  fraction_ac_exp = actual_cys_containing_peps.to_f / expected_cys_containing_peps
  
  special_prob = (3.0 * nsp_prob) + init_prob

  ## Get the final fraction
  #if special_prob < 4.0
  #  #puts the_fractions.join(" ")
  #  puts the_fractions.last
  #  abort
  #end

  # gather data to plot
  the_probs << nsp_prob
  special_probs << special_prob
  the_fractions << fraction_ac_exp 
  
end



hash = {
  'probs' => the_probs,
  'fractions' => the_fractions,
  'special_probs' => special_probs,
}

real_base = file.sub(/\.xml/,'')


=begin
## PROB VS FPR DIFF
base = real_base.dup
base << "." << "prob_FLIPPED_vs_actual_expected_fraction"
base_toplot = base + '.to_plot'
title = "peptide prob (sorted from 0 to 1) vs fraction with cysteines (actual/expected)"
xaxis = "peptide nsp adjusted probability (sorted secondly by init prob)"
yaxis = "fraction with cysteines (actual/expected)"
cats = [['probs', 'fractions']]
plot(base_toplot, base, title, xaxis, yaxis, hash, cats)
=end


=begin
## PROB VS FPR DIFF
base = real_base.dup
base << "." << "prob_vs_actual_expected_fraction"
base_toplot = base + '.to_plot'
title = "peptide prob vs fraction with cysteines (actual/expected)"
xaxis = "peptide nsp adjusted probability (sorted secondly by init prob)"
yaxis = "fraction with cysteines (actual/expected)"
cats = [['probs', 'fractions']]
plot(base_toplot, base, title, xaxis, yaxis, hash, cats)
=end

## SPECIAL PROB VS FPR DIFF
base = real_base.dup
base << "." << "special_prob_vs_actual_expected_fraction"
base_toplot = base + '.to_plot'
title = "peptide prob (special) vs fraction with cysteines (actual/expected)"
xaxis = "(3 * nsp_prob) + init_prob"
yaxis = "fraction with cysteines (actual/expected)"
cats = [['special_probs', 'fractions']]
plot(base_toplot, base, title, xaxis, yaxis, hash, cats)



