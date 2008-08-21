#!/usr/bin/ruby

require 'yaml'
require 'optparse'

$sequest = false
opts = OptionParser.new do |op|
  op.banner = "usage: #{File.basename(__FILE__)} combined.yaml"
  op.separator "outputs values at 99 and 95 % precision"
  op.on("-p", "--params", "outputs sequest params too") { $sequest = true }
end

opts.parse!

if ARGV.size == 0
  puts opts.to_s
  exit
end

# returns the last index of the value from ar that is equal or greater than num
def equal_or_gt(ar, num)
  return_i = nil
  ar.each_with_index do |val,i|
    if val - num >= 0.0
      return_i = i
    end
  end
  return_i
end

file = ARGV.pop
yml = YAML.load_file(file)

comb = {}
yml.each do |filename,hash|
  comb[filename] = {}
  yml_mean = hash['mean']
  yml_stdev = hash['stdev']
  prms = hash['params']
  index99=nil
  index95=nil
  mean_index99_transl = nil
  mean_index95_transl = nil
  hash['estimates'].each do |est_type,esthash|
    index99 = equal_or_gt(esthash['y'], 0.99)
    index95 = equal_or_gt(esthash['y'], 0.95)

    ### NEED TO BE CAREFUL HERE:
    # get the hit number associated with the percentiles
    count99 = esthash['x'][index99]
    count95 = esthash['x'][index95]
    # get the index for the hit number in terms of the mean
    mean_index99_transl = yml_mean['x'].index(count99)
    mean_index95_transl = yml_mean['x'].index(count95)
    # get the precision for the hit number in terms of the mean
    comb[filename][est_type] = 
      {
        'num99' => esthash['x'][index99],
        'num95' => esthash['x'][index95],

        'valprec99' => yml_mean['y'][mean_index99_transl],
        'valprec95' => yml_mean['y'][mean_index95_transl],
        'valstdev99' => yml_stdev['y'][mean_index99_transl],
        'valstdev95' => yml_stdev['y'][mean_index95_transl],
    }
  end
  val_index99 = equal_or_gt(yml_mean['y'], 0.99)
  val_index95 = equal_or_gt(yml_mean['y'], 0.95)
  comb[filename]['val'] = {
    'num99' => (val_index99 ? yml_mean['x'][val_index99] : '-'),
    'num95' => yml_mean['x'][val_index95]
  }
  if $sequest
    cats = %w(xcorr1 xcorr2 xcorr3 deltacn ppm)
    comb[filename]['sequest99'] = cats.map {|cat| prms[cat][index99] }
    comb[filename]['valsequest99'] = cats.map {|cat| prms[cat][val_index99] }
    comb[filename]['sequest95'] = cats.map {|cat| prms[cat][index95] }
    comb[filename]['valsequest95'] = cats.map {|cat| prms[cat][val_index95] }
  end
end

base = file.sub(/#{Regexp.escape(File.extname(file))}$/, '')
outfile = base + "_table_99_95.yml"
File.open(outfile, 'w') {|out| out.print( comb.to_yaml ) }

#### to TABLE:

file = outfile
yml = YAML.load_file(outfile)


def sort_filenames(ar)
  new_ar = ar.map
  order = [   
    'shuffle_cat_HS',
    'reverse_cat_HS',
    'shuffle_HS',
    'reverse_HS',
    'shuffle_cat',
    'reverse_cat',
    'shuffle',
    'reverse',
  ]
  order.each do |guy|
    ar.each do |st|
      if st =~ /#{guy}$/
        new_ar.push( new_ar.delete(st) )
      end
    end
  end
  new_ar
end

# print headings:

base = file.sub(/\.yml$/, '')
outfile = base + '.csv'
File.open(outfile, 'w') do |out|
  out.puts( [nil, nil, '99', nil, nil, nil, '95', nil, nil, nil].join("\t") )
  lil_headings = ['# hits', '# hits (by SBV)', 'mean prec (by SBV)', 'stdev prec (by SBV)' ]

  out.puts( ['db type', 'prec type', *(lil_headings * 2)].join("\t") )
  if $sequest
    sequest_rows = []
  end

  # right now geared for a single type of nonval (like just decoy)
  sort_filenames(yml.keys).each do |filename|
    hash = yml[filename]
    better_filename = filename.sub(/orbi_|scx_/,'').gsub('_', ' ').sub(/shuffle/, 'shf').sub(/reverse/, 'rev')
    
    val_hash = hash.delete('val')
    hash.each do |k,est_hash|
      next if k =~ /sequest/
      row = [better_filename]   
      row.push(k)
      row.push( est_hash['num99'], val_hash['num99'], est_hash['valprec99'], est_hash['valstdev99'], est_hash['num95'], val_hash['num95'], est_hash['valprec95'], est_hash['valstdev95'])
      out.puts( row.join("\t") )
    end
    if $sequest
      [['sequest99', 'sequest95'], ['valsequest99', 'valsequest95']].each do |pair|
        row = [better_filename]
        label = if pair[0] =~ /^val/
                  'SBV'
                else
                  'decoy'
                end
        row.push(label)
        first = hash[pair[0]]
        second = hash[pair[1]]
        row.push( *(first + second) )
        sequest_rows.push( row.join("\t") ) 
      end
    end
  end

  if $sequest
    lil_sequest = %w[xcorr(+1) xcorr(+2) xcorr(+3) deltacn ppm]
    sequest_rows.unshift( ['filename', 'type', *(lil_sequest * 2) ].join("\t") )
    sequest_rows.unshift( [nil, nil, '99', nil, nil, nil, nil, '95', nil, nil, nil, nil].join("\t") )
    sequest_rows.unshift('')
    out.puts sequest_rows.join("\n")
  end
end
