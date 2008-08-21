#!/usr/bin/ruby

require 'optparse'
require 'table'

require 'ms/gradient_program'

delimiter = "\t"
table_format = false
opts = OptionParser.new do |op|
  op.banner = "#{File.basename(__FILE__)} [OPTIONS] <file>.meth"
  op.on("-d", "--delimiter <tab|space|format>", "delimiter (tab default)", "format = space delimited, formatted ascii table") do |v|
    if v == 'space'
      delimiter = " "
    elsif v == 'tab'
      delimiter = "\t"
    elsif v == 'format'
      table_format = true
    else
      abort "don't recognize #{v}"
    end
  end
end

opts.parse!

if ARGV.size == 0
  puts opts
  exit
end


sets_of_tables = {}
ARGV.each do |file|
  File.open(file) do |fh|
    sets_of_tables[file] = GradientProgram.all_from_handle(fh)
  end
end

sets_of_tables.each do |file, tables|
  puts "FILE: #{file}"
  tables.each do |gp|
    puts "PUMP_TYPE: #{gp.pump_type}"
    col_labels = ["time(min)", "%A", "%B", "%C", "%D", "ul/min"]
    data = gp.time_points.map do |tp|
      line = [tp.time, *(tp.percentages)]
      line << tp.flow_rate
    end
    table = Table.new(data, nil, col_labels)
    if table_format
      puts table.to_formatted_string
    else
      puts table.to_s(delimiter)
    end
  end
end
