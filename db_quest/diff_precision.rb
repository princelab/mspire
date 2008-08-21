#!/usr/bin/ruby

require 'optparse'
require 'data_sets'
require 'ruport'

#######################################################
# MAIN:
#######################################################

opt = {}
opts = OptionParser.new do |op|
  op.banner = "usage: #{File.basename(__FILE__)} <file1>.yaml ..."
  op.separator "averages all validators but decoy and outputs the abs diff for each file"
  op.on("-b", "--by_sequest <attribute>", "attribute = deltacn, ppm, xcorr<n>") {|v| opt[:by_sequest_att] = v }
  op.on("-a", "--average", "average similar types") {|v| opt[:average] = v }
  op.on("--average_all", "average all but decoy") {|v| opt[:average_all] = v }
  op.on("--csv", "output cols in csv format (tabs)") {|v| opt[:csv] = v }
end

opts.parse!

if ARGV.size == 0
  puts opts
  exit
end

files = ARGV.to_a

all_records_table = Table(%w(type label hits_separate include_dcnstar postfilter catenated decoy_by data).map {|v| v.to_sym})
files.each do |filename|
  basename = File.basename(filename.sub(/\.yaml$/,''))

  data_sets = DataSets.load_from_filter_file(filename, opt)

  if opt[:average]
    data_sets.average {|v| v.tp == 'badAA' }
    data_sets.average {|v| v.tp == 'tmm' }
    data_sets.average {|v| v.tp == 'bias' }
  elsif opt[:average_all]
    data_sets.average('average_all') {|v| v.tp != 'decoy' }
  end

  data_sets.put_first {|v| v.tp == 'decoy' }

  decoy = data_sets.shift
  next if decoy.tp != 'decoy'

  decoy_data = decoy.ydata
  others_data = data_sets.map {|dss| dss.ydata }

  abs_diff_ar = others_data.map do |other|
    decoy_data.zip(other).map {|dec,ot| (dec.to_f - ot).abs }
  end
  
  #all_dsets.push( *(labels.zip(abs_diff_ar).map {|label, data| DataSet.new(nil, data) {|g| g.label = label } }) )

  abs_diff_ar.zip(data_sets).each do |data, ds|

    hash = {}
    hash[:type] = ds.tp

    hash[:label] = ds.label

    # hits separate
    if basename.match(/hits_separate/)
      hash[:hits_separate] = true
    else
      hash[:hits_separate] = false
    end

    # include_dcnstar
    if basename.match(/dcn-t/)
      hash[:include_dcnstar] = true
    elsif basename.match(/dcn-f/)
      hash[:include_dcnstar] = false
    else ; raise RuntimeError
    end

    # postfilter
    if basename.match(/-ac$/)
      hash[:postfilter] = 'aaseq_charge'
    elsif basename.match(/-a$/)
      hash[:postfilter] = 'aaseq'
    elsif basename.match(/-s$/)
      hash[:postfilter] = 'scan'
    else ; raise RuntimeError
    end

    # catenated
    if basename.match(/_cat/)
      hash[:catenated] = true
    elsif basename.match(/_sep/)
      hash[:catenated] = false
    else ; raise RuntimeError
    end

    # decoy_by
    if basename.match(/^inv/)
      hash[:decoy_by] = 'inverse'
    elsif basename.match(/^normal/)
      hash[:decoy_by] = nil
    elsif basename.match(/^shuff/)
      hash[:decoy_by] = 'shuffle'
    else ; raise RuntimeError
    end

    hash[:data] = data

    all_records_table << hash
  end
end
#all_dsets.to_csv('diffs.csv')

# average the value within each record
##  NOTE: This guy will work on random, but not on stringency....
all_records_table.data.each do |record|
  record[:data] = record[:data].inject(0.0) {|m,v| m + v}/(record[:data].size)
end

def average_records(records)
  records.inject(0.0) {|s,v| s + v[:data] }/records.size
end


def avg_hits_separate(all_records_table)
  output_table = Group('Choosing Top Hit (Hits Separate vs. Hits Together)', :column_names => [:hits_separate, :avg])
  grouping = Grouping(all_records_table, :by => :hits_separate)
  grouping.each do |name, g|
    output_table << [name, average_records(g.data)]
  end   
  output_table
end

def hits_separate_by_postfilter(all_records_table)
  output_table = Group('Hits Separate vs. Hits Together by Postfilter', :column_names => [:postfilter, :hits_separate, :avg])
  grouping = Grouping(all_records_table, :by => [:hits_separate, :postfilter])
  grouping.each do |hs_name, g|
    g.subgroups.each do |pf_name, pf_g|
      output_table << [pf_name, hs_name, average_records(pf_g.data)]
    end
  end   
  output_table
end

def just_ht_inv(all_records_table)
  puts all_records_table.to_csv
  output_table = all_records_table.sub_table([:include_dcnstar, :catenated, :postfilter, :data]) {|r| r[:decoy_by] == 'inverse' }
  output_table
end


all_groups = []

# just for now
all_groups << avg_hits_separate(all_records_table)

avg_hs_by_pf = hits_separate_by_postfilter(all_records_table)
all_groups << avg_hs_by_pf

all_groups << Grouping(avg_hs_by_pf, :by => :postfilter)
all_groups << Grouping(avg_hs_by_pf, :by => :hits_separate)


###### just hits together, invCAT vs. sepCAT
just_ht = just_ht_inv(all_records_table)
just_ht.rename_column(:data, :avg)

all_groups << just_ht

with_include_dcnstar_true = just_ht.sub_table {|record| record[:include_dcnstar] == true }

puts with_include_dcnstar_true

avg_dcn_table = Table([:catenated, :postfilter, :avg])
grouping = Grouping(just_ht, :by => [:catenated, :postfilter])


grouping.data.each do |cat_val, cat_subgroup|
  cat_subgroup.subgroups.each do |pf_val, pf_subgroup|
    dcn_both_avg = pf_subgroup.data.inject(0.0) {|m,r| m + r[:avg] }/pf_subgroup.size
    avg_dcn_table  << [cat_val, pf_val, dcn_both_avg]
  end
end

puts "AVG DCN table: "
puts avg_dcn_table


#all_groups.each do |group|
#  puts group
#end


## averaging dcnstar

## include dcnstar


###### HT, avg vs. shuff


