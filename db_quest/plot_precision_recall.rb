#!/usr/bin/ruby

require 'optparse'

def files_to_plot(files, proteins=false)
  files.each do |filename|
    basename = filename.sub(/\.yaml$/, '')
    ys_by_val = {}
    num_hits = []
    prot_num_hits = []
    prots_by_val = {}
    File.open( filename ) do |fh|
      num_docs = 0
      YAML.load_documents( fh ) do |ydoc|
        ydoc['pephits_precision'].each do |k, prec|
          ys_by_val[k] ||= []
          ys_by_val[k] << prec
        end
        if proteins

          ydoc['prothits_precision'].each do |k, prec_triple|
            keys = %w(worst normal normalUp normalDown)
            prots_by_val[k] ||= {}
            keys.each do |key|
              prots_by_val[k][key] ||= []
            end

            prots_by_val[k]['worst'] << prec_triple['worst']
            normal = prec_triple['normal']
            #p normal
            #puts "STDEV"
            stdev =  prec_triple['normal_stdev']
            #p (normal + stdev)
            prots_by_val[k]['normal'] << normal
            prots_by_val[k]['normalUp'] << (normal + stdev)
            prots_by_val[k]['normalDown'] << (normal - stdev)
          end
        end
        num_hits << ydoc['pephits']
        num_docs += 1
        if proteins
          prot_num_hits << ydoc['prothits']
        end
      end
    end
    all_dsets = ys_by_val.map do |cat, ar|
      dset = {}
      dset[:title] = cat
      dset[:xvals] = num_hits
      dset[:yvals] = ar
      dset
    end
    if proteins
      prots_by_val.each do |k, kind_hash|
        dsets = kind_hash.map do |kind, ar|
          puts kind
          dset = {}
          dset[:title] = "#{k} prot (#{kind.to_s.gsub(' ','')})"
          dset[:xvals] = prot_num_hits
          dset[:yvals] = ar
          dset
        end
        all_dsets.push( *dsets )
      end
    end
    data_type = "XYData"
    out_file = basename
    title = "precision-recall plot"
    xaxis = 'num hits (recall)'
    yaxis = 'precision (TP/TP+FP)'

    File.open(basename + '.to_plot', 'w') do |out|
      # print header
      [data_type, out_file, title, xaxis, yaxis].each do |thing|
        out.puts thing
      end
      all_dsets.each do |dset|
        out.puts dset[:title]
        out.puts dset[:xvals].join(' ')
        out.puts dset[:yvals].join(' ')
      end
    end
  end
end


opt = {}
opts = OptionParser.new do |op|
  op.banner = "usage: #{File.basename(__FILE__)} filter_validate.yaml ..."
  op.on("-p", "--proteins", "include protein precision") {|v| opt[:proteins] = true }
end

opts.parse!

if ARGV.size == 0
  puts opts
  exit
end


files_to_plot(ARGV.to_a, opt[:proteins])


