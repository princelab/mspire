#!/usr/bin/ruby -w

require 'generator'
require 'optparse'
require 'yaml'

require 'data_sets'


$average = false
$errorbars = false
$no_cys_est = false
$avgpts = nil
$average_all = false
$zscore = false
$to_r = false
$combined = false
opts = OptionParser.new do |op|
  op.banner = "usage: #{File.basename(__FILE__)} <file>.yaml ..."
  op.on("-a", "--average", "average similar types") {|v| $average = v }
  op.on("-e", "--errorbars", "make gnuplot errorbar data") {|v| $errorbars = v}
  op.on("-z", "--zscore", "make plot of zscore by num hit") {|v| $zscore = v}
  op.on("--no_cys_est", "drop the cysteine estimate") {|v| $no_cys_est= v}
  op.on("--avgpts <I>", Integer, "avg that many data points") {|v| $avgpts = v}
  op.on("--average_all", "average all validators (not prob or qval or decoy)") {|v| $average_all = v}
  op.on("--to_r", "sends data to file for processing") {|v| $to_r = v }
  op.on("--combined", "calcs avgs and zscores and outputs combined.yaml") {|v| $combined = v }
end

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



opts.parse!

if ARGV.size == 0
  puts opts.to_s
  exit
end

default_to_plot = {:type => 'XYData', :title => 'validation', :xaxis => 'hit_number (ordered by prob [and much more])', :yaxis => 'precision [TP/(TP+FP)]'}

files = ARGV.to_a


if $combined
  comb = {}
end


files.each do |file|
  st = YAML.load_file(file)

  num_values = st[:pephits_precision].first[:values].size
  by_hit_number = (1..num_values).to_a

  cnt = -1  # adjusted to start at 0 inside map loop
  data_sets = st[:pephits_precision].map do |x|
    cnt += 1
    DataSet.new(by_hit_number, x[:values], st[:params][:validators][cnt])
  end
  dsets = DataSets.new(data_sets)
  base_name = file.sub(/\.yaml$/, '')


  if $to_r
    dsets.to_r(base_name + '.rdat')
    next
  end

  if $avgpts
    base_name << '_avgpts' + $avgpts.to_s
    dsets.each do |ds|
      ds.avg_points!($avgpts)
    end
  end

  if $no_cys_est
    dsets.delete_if {|v| v.label == 'cysteine (est)'}
  end

  to_avg = lambda {|v| v.tp != 'qval' and v.tp != 'prob' and v.tp != 'decoy'}
  not_averaging = lambda {|v| v.tp == 'qval' or v.tp == 'prob' or v.tp == 'decoy'}
  if $average
    dsets.average {|v| v.tp == 'badAA' }
    dsets.average {|v| v.tp == 'tmm' }
    dsets.average {|v| v.tp == 'bias' }
    base_name << '_avg'
  elsif $errorbars or $zscore or $combined
    av_std = dsets.average_stdev('others', &to_avg)
    dsets.reject!(&to_avg)
    nonavg = dsets
  elsif $average_all
    dsets.reject!(&not_averaging)
    label = dsets.map {|v| v.label }.join(", ")
    puts "averaging: #{dsets.map {|ds| ds.tp}.join(' ')}"
    dsets.average(label, &to_avg)
  end

  if $errorbars
    # labels:
    File.open(base_name + '_errorbars.dat', 'w') do |out|

      datasets = []
      datasets.push(nonavg.first.xdata)

      nonavg.put_first {|v| v.tp == 'prob' or v.tp == 'qval' } ## this or qval
      nonavg.put_last {|v| v.tp == 'decoy' } ## this or qval

      labels = nonavg.map {|v| v.label }
      labels.push('mean', 'stdev')
      labels.unshift('# xdata')

      abort 'prob not first' unless nonavg.first.tp == 'prob' or nonavg.first.tp == 'qval'

      nonavg.each {|ds| datasets.push( ds.ydata ) }

      datasets.push(av_std.ydata[0])
      datasets.push(av_std.ydata[1])

      # add the labels to the top
      datasets.zip(labels) do |ar,label|
        ar.unshift(label)
      end
      SyncEnumerator.new(*datasets).each do |row|
        out.puts row.join("\t")
      end
    end
  end
  if $zscore or $combined

    if $combined
      comb[base_name] = {'mean' => { 'x' => av_std.xdata.dup,
                                       'y' => av_std.ydata[0].dup },
                           'stdev' => { 'x' => av_std.xdata.dup,
                                        'y' => av_std.ydata[1].dup }
      }

        comb[base_name]['estimates'] = {}
        nonavg.each do |ds|
          label = ds.label.split(/[\.\s]/)[0]
          comb[base_name]['estimates'][label] = {
            'x' => ds.xdata.dup,
            'y' => ds.ydata.dup
          }
        end
      end

    nonavg.each do |testing_ds|
      new_x_data = []
      new_y_data = []

      testing_ds.ydata.zip(testing_ds.xdata, av_std.ydata[0], av_std.ydata[1]).each do |x,hit_num,mean,stdev|
        val = (x.to_f - mean) / stdev
        unless val.nan? or val.infinite?
          new_x_data << hit_num
          new_y_data << val
        end
      end
      testing_ds.xdata = new_x_data
      testing_ds.ydata = new_y_data
    end

    if $combined
      comb[base_name]['zscores'] = {}
      nonavg.each do |ds|
        p ds.label
        label = ds.label.split(/[\.\s]/)[0]
        comb[base_name]['zscores'][label] = {
            'x' => ds.xdata,
            'y' => ds.ydata
        }
      end
    else
      nonavg.each {|ds| ds.label = base_name + ' ' + ds.label }

      nonavg.print_to_plot(default_to_plot.merge({ :file => base_name + '.zscore', :yaxis => 'zscore' }))
    end
  else #normal output
    dsets.put_first {|v| v.tp == 'prob' } ## this or qval
    dsets.put_first {|v| v.tp == 'qval' }
    dsets.put_last {|v| v.tp == 'decoy' }

    dsets.print_to_plot(default_to_plot.merge({:file => base_name}))
  end


end


if $combined
  File.open('combined.yaml', 'w') {|v| v.print(comb.to_yaml) }
end




