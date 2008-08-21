#!/usr/bin/ruby

require 'yaml'
require 'gnuplot'
require 'xmlparser' # to read the parse errors
require 'vec'

require 'optparse'

c = {'read' => 'time_to_read', 'access' => 'time_to_access', 'total' => 'total_time_to_read_and_access' }

variable = c['read']

opts = OptionParser.new do |op|
  op.banner = "usage: #{File.basename(__FILE__)} *.yml"
  op.on("-r", "--read", "plots time to read") {|v| variable = c['read'] }
  op.on("-a", "--access", "time to access") {|v| variable = c['access'] }
  op.on("-t", "--total", "total time to read and access") {|v| variable = c['total'] }
end

opts.parse!

if ARGV.size == 0
  puts opts.to_s 
  exit
end

files = ARGV.to_a

# file_size in MB
def time_to_read_and_file_size(files, variable, tp)
  variable_data = []
  file_size = []
  num_files_too_big = 0
  files_with_errors = []
  num_total_files = 0
  files_with_no_data = []
  files.each do |file|
    file_last_read = file
    begin
      File.open(file) do |fh|
        YAML.load_documents(fh) do |yml|
          yml.each do |file_entry|
            num_total_files += 1
            #1 bytes = 9.53674316 × 10-7 megabytes
            fs = (file_entry['file_size'] * 9.53674316e-7)
            if file_entry.key? 'error'
              files_with_errors << "#{File.basename(file)}: #{file_entry['file']}"
            elsif file_entry.key? 'limit' # means the file size was too big!
              num_files_too_big += 1
            elsif file_entry[variable].nil?
              files_with_no_data << "NO DATA: #{File.basename(file)}: #{file_entry['file']} (for #{variable})\n"
            else
              variable_data <<  file_entry[variable]
              file_size << fs
            end
          end
        end
      end
    rescue
      puts "probably a bad yml file!"
      puts $!
      puts "File working on: #{file_last_read}"
      exit
    end
  end
  puts "***************************************************************"
  puts "#{variable} :: #{tp}"
  puts "#{num_files_too_big} files too big for #{tp}" if num_files_too_big > 0
  if files_with_errors.size > 0
    puts(files_with_errors.map {|f| "ERROR: #{f}\n"}.join)
  end
  puts files_with_no_data.join
  puts "TOTAL FILES: #{num_total_files}"
  puts "TOTAL FILES READ: #{file_size.size}  (MISSING: #{num_total_files - file_size.size})"

  [variable_data, file_size]
end

(fl, all) = files.to_a.partition do |file|
  file =~ /_fl_/
end

hash = {'access first and last scan' => fl, 'access all scans' => all}

hash.each do |key,fl|
  if fl.size > 0
    hash = Hash.new {|h,k| h[k] = [] }
    fl.each do |f|
      base = f.sub(/\.yml$/,'')
      pieces = base.split('_')
      2.times { pieces.shift }
      tp = pieces.join("_")
      hash[tp] << f
    end

    tp_ttr_fs = hash.map do |tp, fles|
      [tp, *(time_to_read_and_file_size(fles, variable, tp))]
    end

    Gnuplot.open do |gp|
      Gnuplot::Plot.new( gp ) do |plot|
        var = variable.gsub('_',' ')
        plot.terminal "svg dynamic fname \"arial\""
        plot.output("#{key}_#{variable}.svg".gsub(/\s+/, '_'))
        plot.key 'left top'
        plot.title key
        plot.xlabel "file size (MB)"
        plot.ylabel "#{var} (sec)"


        pts = [6,4,8,1]
        # postscipt: 1=+, 2=X, 3=*, 4=square, 5=filled square, 6=circle,
        #            7=filled circle, 8=triangle, 9=filled triangle, etc.
        tp_ttr_fs.each do |tp, ttr, fs|
          if ttr.include? nil
            abort 'has nil!'
          end
          plot.data << Gnuplot::DataSet.new( [fs, ttr] ) do |ds|
            (rsq, slope, yint) = VecD.new(fs).rsq_slope_intercept(VecD.new(ttr))
            puts "TP: #{tp} RSQ: #{rsq}, SLOPE: #{slope}, YINT: #{yint}"
            ds.with = "points pt #{pts.shift} ps 0.5"

            ds.title = tp
          end
        end
      end
    end
  end
end

