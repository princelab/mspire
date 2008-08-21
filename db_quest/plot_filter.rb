#!/usr/bin/ruby -w

require 'optparse'
require 'data_sets'
require 'vec'


# IMPLEMENTS the COMBINED INTERFACE:
# (combined) x is always num hits
# <filename>:
# ## means for PR:
#   mean:
#      x:
#      y:
# ## vals std for errorbars
#   stdev:
#      x: 
#      y:
# ## PR estimates for comparison:
#   estimates:
#      prob:
#        x:
#        y:
#      qval:
#        x:
#        y:
#      decoy:
#        x:
#        y:
# ## zscores zscore
#   zscores:
#      prob:
#        x:
#        y:
#      qval:
#        x:
#        y:
#      decoy:
#        x:
#        y:
#
# ## also adds the key params:
#   params:
#      xcorr1:
#      xcorr2:
#      xcorr3:
#      deltacn:
#      ppm:



opt = {}
opts = OptionParser.new do |op|
  op.banner = "usage: #{File.basename(__FILE__)} [OPTIONS] *.yaml"
  op.separator "plots stuff"
  op.on("--zscore <N>", Integer, "makes histograms by zscore (decoy vs. other vals) with N bins") {|v| opt[:zscore] = v }
  ## ALSO, WEIGHTED BY NUM HITS
  # plot avg, stdev, decoy on x axis (x axis = num hits, or dcn, or ...)
  op.on("--pr N", Integer, "gives precision/recall data to_plot",
                "[the top precision per N num hits]") {|v| opt[:pr] = v }
  op.on("--prz N", Integer, "gives P/R and zscore plots",
                "[the top precision per N num hits]") {|v| opt[:prz] = v }
  op.on("--combined [N]", Integer, "outputs P/R and Z score in combined.yaml") {|v| opt[:combined] = v }
end

opts.parse!

if ARGV.size == 0
  puts opts.to_s
  exit
end

to_avg = lambda {|v| v.tp != 'qval' and v.tp != 'prob' and v.tp != 'decoy'}
not_averaging = lambda {|v| v.tp == 'qval' or v.tp == 'prob' or v.tp == 'decoy'}

files = ARGV.to_a

comb = {}

files.each do |filename|
  base = filename.sub(/\.\w+$/,'')

  (dsets,params,num_hits) = DataSets.load_filter_file(filename)

  if opt[:prz] or opt.has_key?(:combined)
    new_label = dsets.select(&to_avg).map {|v| v.label }.join(', ')
    avg_std = dsets.average_stdev(new_label, &to_avg)
    decoy = dsets.reject!(&to_avg)  # this will be decoy or nothing!
    if decoy.size == 1
      decoy = decoy.first
    else
      puts "SKIPPING #{filename} (has no decoy data for zscore!)"
      next
    end

    zscores = decoy.ydata.zip(avg_std.ydata[0], avg_std.ydata[1]).map do |decoy_val,avg,stdev|
      zscore = (decoy_val - avg) / stdev
      if zscore.nan? ; nil
      elsif zscore.infinite? ; nil
      else ; zscore
      end
    end
    quints_not_nil = []
    avg_std.xdata.zip(avg_std.ydata[0], avg_std.ydata[1], params['xcorr1'], params['xcorr2'], params['xcorr3'], params['deltacn'], params['ppm'], decoy.ydata, zscores) do |num_hits,avg,stdev,xcorr1,xcorr2,xcorr3,deltacn,ppm,decoy,zscore|
      unless zscore.nil?
        quints_not_nil << [num_hits, avg, stdev, xcorr1,xcorr2,xcorr3,deltacn,ppm, decoy, zscore]
      end
    end
    quints_not_nil.sort!

    ar_of_quints = 
      if !opt[:combined].nil?
        # take the max in opts[:prz] points!  # see max_in_points!
        hashed_by_x = quints_not_nil.hash_by {|quint| quint[0] }

        max_x = hashed_by_x.keys.sort.last
        number = if opt[:prz]
                   opt[:prz]
                 elsif opt[:combined]
                   opt[:combined]
                 end

        iterations = max_x / number
        max_per_group = []
        (iterations+1).times do |i|
          start_i = i * number
          end_i = (i+1) * number ## exclusive
          this_group = []
          (start_i...end_i).each do |num_hits|
            if hashed_by_x.key? num_hits
              this_group.push( *(hashed_by_x[num_hits]) )
            end
          end
          max_per_group.push( this_group.sort_by {|trp| [trp[1],trp[0],-(trp[9].abs)]}.last )  # sorting by [y,x]
        end
        max_per_group
      else
        quints_not_nil
      end

    new_x = []; new_y = [];  decoy_precision = [] ; stdevs = [] ; new_zscore = []
    xcorr1_ar = []
    xcorr2_ar = []
    xcorr3_ar = []
    deltacn_ar = []
    ppm_ar = []

    ar_of_quints.each do |quint|
      if quint
        new_x << quint[0]
        new_y << quint[1]
        stdevs << quint[2]
        xcorr1_ar << quint[3] 
        xcorr2_ar << quint[4] 
        xcorr3_ar << quint[5]
        deltacn_ar << quint[6]
        ppm_ar << quint[7]
        decoy_precision << quint[8]
        new_zscore << quint[9]
      end
    end

    pr = DataSet.new do |ds|
      ds.xdata = new_x
      ds.ydata = new_y
      ds.label = base + ' (avg) ' + new_label
    end
    z = DataSet.new do |ds|
      ds.xdata = new_x
      ds.ydata = new_zscore
      ds.label = base + ' decoy zscore'
    end
    stdevs_ds = DataSet.new do |ds|
      ds.xdata = new_x
      ds.ydata = stdevs
      ds.label = base + ' stdevs'
    end
    decoy_pr = DataSet.new do |ds|
      ds.xdata = new_x
      ds.ydata = decoy_precision
      ds.label = base + ' decoy precision'
    end

    if opt[:prz]
      DataSets.new([pr]).print_to_plot( {:type => 'XYData', :file => base, :title => base + " PR", :xaxis => 'num_hits', :yaxis => 'precision [TP/(TP+FP)]'} )
      DataSets.new([z]).print_to_plot(  {:type => 'XYData', :file => base + '_zscore', :title => base + " decoy zscore", :xaxis => 'num_hits', :yaxis => 'zscore'} )
    else  # opt[:combined]
      comb[base] = { 
        'mean' => { 
          'x' => pr.xdata,
          'y' => pr.ydata,
        },
        'stdev' => {
          'x' => stdevs_ds.xdata,
          'y' => stdevs_ds.ydata,
        },
        'zscores' => {
          'decoy' => {
            'x' => z.xdata,
            'y' => z.ydata,
          },
        },
        'estimates' => {
          'decoy' => {
            'x' => decoy_pr.xdata,
            'y' => decoy_pr.ydata,
          }
        },
        'params' => {
          'xcorr1' => xcorr1_ar,
          'xcorr2' => xcorr2_ar,
          'xcorr3' => xcorr3_ar,
          'deltacn' => deltacn_ar,
          'ppm' => ppm_ar,
        }
      }
    end
  elsif opt[:zscore]
    # really only decoy applies here...
    # av_std is a weird dataset (2 y values)
    new_label = dsets.select(&to_avg).map {|v| v.label }.join(', ')
    avg_std = dsets.average_stdev(new_label, &to_avg)

    # get the decoy set
    decoy = dsets.reject!(&to_avg)  # this will be decoy or nothing!
    if decoy.size == 1
      decoy = decoy.first
    else
      puts "SKIPPING #{filename} (has no decoy data for zscore!)"
      next
    end

    zscores = decoy.ydata.zip(avg_std.ydata[0], avg_std.ydata[1]).map do |decoy,avg,stdev|
      zscore = (decoy - avg) / stdev
      if zscore.nan? ; nil
      elsif zscore.infinite? ; nil
      else ; zscore
      end
    end
    zscores.compact!

    ## custom bins
    custombins = [-27.5,-22.5,-17.5,-12.5,-7.5,-2.5,0,2.5,7.5]
    (bins, freqs) = VecD.new(zscores).histogram(custombins)
    #(bins, freqs) = VecD.new(zscores).histogram(opt[:zscore])
    File.open(base + '_zhist.to_plot', 'w') do |out|
      out.puts( ['XYData', base + '_zhist', 'zscore (decoy - avg_val) ' + new_label, 'zscore', 'frequency', base, bins.join(' '), freqs.join(' ')].join("\n") )
    end

  elsif opt[:pr]
    
    new_label = dsets.select(&to_avg).map {|v| v.label }.join(', ')
    new_ds = dsets.average_to_new_ds(new_label, &to_avg)
    new_ds.sort_by_x!
    new_ds.max_in_points!(opt[:pr])
    header_hash = 
    DataSets.new([new_ds]).print_to_plot({:type => 'XYData', :file => base, :title => base + " PR", :xaxis => 'num_hits', :yaxis => 'precision [TP/(TP+FP)]'})
  end



end

if opt.has_key?(:combined)
  postfix = if opt[:combined]
              opt[:combined]
            else
              'all_not_nil'
            end
  File.open("combined_#{postfix}.yaml", 'w') {|out| out.print comb.to_yaml }
end

