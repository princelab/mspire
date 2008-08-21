#!/usr/bin/ruby -w

# CONSTANTS:
msrun = "orbi"
db_quest_dir = '/project/marcotte/marcotte/john/db_quest'
base_dir = db_quest_dir + "/cat_vs_separate/#{msrun}"

fasta_file = db_quest_dir + '/databases_stock/SCall_20060414_clean.fasta'
nice_cmd = 'nice -n +19 '
base_cmd = nice_cmd + "filter_and_validate.rb"
decoy_on_match = true
aa = 'C'
params_file = base_dir + '/normal_KRP/yeast.params'

hash = {
  :inv_cat => 
  {
    :file => base_dir + '/reverse_cat_KRP/bioworks.srg',
    :decoy_flag => '/^INV_/',
  },
  :inv_sep => 
  {
    :file => base_dir + '/normal_KRP/bioworks.srg',
    :decoy_flag => base_dir + '/reverse_KRP/bioworks.srg'
  },
  :shuff_cat => {
    :file => base_dir + '/shuffle_cat_KRP/bioworks.srg',
    :decoy_flag => '/^SHUFF_/',
  },
  :shuff_sep => {
    :file => base_dir + '/normal_KRP/bioworks.srg',
    :decoy_flag => base_dir + '/shuffle_KRP/bioworks.srg'
  },
  :normal => 
  {
    :file => base_dir + '/normal_KRP/bioworks.srg',
    :decoy_flag => nil
  },
}
proteins_flag = "--proteins"

filter_file = base_dir + '/filters/everything.txt'

# tmm
phobius_file = db_quest_dir + '/phobius_stock/SCall_20060414_clean.phobius.small.txt'
toppred_file = db_quest_dir + '/toppred_stock/SCall_20060414_clean.toppred.out.txt'
soluble_fraction = true

# bias
mrna_bias_file = db_quest_dir + '/abundance_bias/yeast_abundance_min_1.0_mrna_ch.fasta'
prot_bias_file = db_quest_dir + '/abundance_bias/yeast_abundance_min_3000.0_prot_ch.fasta'

###################################################
# MODULATE:
###################################################
hits_separate_flag = "--hits_separate"
#hits_separate_flag = ""
min_tmm = 1
min_tmm2 = 2
#no_include_tmm = false
#no_include_tmm = 0.8
tmm_bkg = 0.0
bias_bkg = 0.0
bad_aa_bkg = 0.0

#order = [:normal, :inv_cat, :shuff_cat, :inv_sep, :shuff_sep]
order = [:normal, :inv_cat, :shuff_cat]

letter = 'A'

order.each do |key|
  v = hash[key]
  digestion_args = "--digestion #{fasta_file},#{params_file}"
  decoy_args = 
    if v[:decoy_flag] ; "--decoy #{v[:decoy_flag]}"
    else ; ''
    end
   
  interactive = "-i #{filter_file}"
  # bad aa
  bad_aa_args = "--bad_aa #{aa},true,#{bad_aa_bkg} --bad_aa #{aa},false,#{bad_aa_bkg}"
  # tmm
  toppred_args = "--tmm #{toppred_file},#{min_tmm},#{soluble_fraction},0.8,#{tmm_bkg} --tmm #{toppred_file},#{min_tmm2},#{soluble_fraction},0.8,#{tmm_bkg} --tmm #{toppred_file},#{min_tmm},#{soluble_fraction},false,#{tmm_bkg} --tmm #{toppred_file},#{min_tmm2},#{soluble_fraction},false,#{tmm_bkg}"
  phobius_args =  "--tmm #{phobius_file},#{min_tmm},#{soluble_fraction},0.8,#{tmm_bkg} --tmm #{phobius_file},#{min_tmm2},#{soluble_fraction},0.8,#{tmm_bkg} --tmm #{phobius_file},#{min_tmm},#{soluble_fraction},false,#{tmm_bkg} --tmm #{phobius_file},#{min_tmm2},#{soluble_fraction},false,#{tmm_bkg}"
  tmm_args = toppred_args + ' ' + phobius_args
  # bias
  mrna_bias = "--bias #{mrna_bias_file},true,#{bias_bkg}"
  prot_bias = "--bias #{prot_bias_file},true,#{bias_bkg}"
  bias_args = mrna_bias + ' ' + prot_bias
  # output
  output_file = "#{key}#{hits_separate_flag}.yaml"
  output_args = "-o yaml:#{output_file}"

  to_run = [base_cmd, v[:file], interactive, proteins_flag, digestion_args, decoy_args, bad_aa_args, tmm_args, bias_args, output_args, hits_separate_flag].join(" ")
  File.open("run_comparisons__HS__#{letter}.sh", 'w') {|fh| fh.chmod(0755); fh.puts to_run }
  letter = letter.next
end
