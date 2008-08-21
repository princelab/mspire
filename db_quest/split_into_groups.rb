#!/usr/bin/ruby -w

require 'fileutils'

fu = FileUtils

###########################################
###########################################
$num_filters = 51
$num_rand_filters = 500
###########################################

include_dcnstar = %w(t f)
# scan aaseq aaseq+charge
postfilter = %w(s a ac)
#postfilter = %w(ac)
#postfilter = %w(s a)

#by_postfix = %w(all rand dcn ppm xcorr)  # for everything.txt runs
by_postfix = %w(all)   # for stringency.txt runs (background)
#by_postfix = %w(rand)   # for stringency.txt runs (background)
###########################################
###########################################

if ARGV.size == 0
  puts "usage: #{File.basename(__FILE__)} PRECISION*.yaml"
  puts "outputs files <file> #{by_postfix.join(', ')} (currently splits at #{$num_filters})"
  exit
end

ARGV.each do |file|
  basename = file.sub(/\.yaml$/, '')
  File.open(file) do |fh|
    include_dcnstar.each do |i_dcns|
      postfilter.each do |pf|
        by_postfix.each do |by|

          stop_at = $num_filters
          stop_at = $num_rand_filters if by == 'rand'
          
          File.open(basename + "__#{by}_dcn-#{i_dcns}_pf-#{pf}" + '.yaml', 'w') do |out|
            counter = 0
            prev_pos = nil
            while line = fh.gets
              if line =~ /^---/
                if counter == stop_at
                  fh.pos = prev_pos
                  break
                end
                counter += 1 
              end
              out.print(line)
              prev_pos = fh.pos
            end
          end
        end
      end
    end
  end
end

# organize into folders
by_postfix.each do |by|
  fu.mkdir by
  files = Dir["*__#{by}_*"]
  files.each do |file|
    fu.move( file, by )
  end
end
