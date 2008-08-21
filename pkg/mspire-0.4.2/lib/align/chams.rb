
require 'ms/msrun'

module Align; end
class Align::CHAMS

  # Avg_score	0.52559
  # Scan1	Scan2	Edge_cost	Path_cost	Edge_direction
  attr_accessor :avg_score, :time_mscans, :time_nscans, :mscans, :nscans, :edge_costs, :path_costs, :directions
  
  # requires an object that will respond to [<scan_num>] to give time
  # (seconds) for each file
  def initialize(chams_file, time_by_scan_num1, time_by_scan_num2)
    @time_mscans = []
    @time_nscans = []
    @mscans = []
    @nscans = []
    @edge_costs = []
    @path_costs = []
    @directions = []
    read_chams_file(chams_file)
    @mscans.each_with_index do |scan,i|
      @time_mscans[i] = time_by_scan_num1[scan]
    end
    @nscans.each_with_index do |scan,i|
      @time_nscans[i] = time_by_scan_num2[scan]
    end
  end

  def read_chams_file(chams_file)
    File.open(chams_file).each do |line|
      if line =~ /[\d\w]/
        if line =~ /^# Avg_score ([\.\d])/
          @avg_score = $1.to_f
          next
        end
      end
      if line =~ /^#/
        next
      end
      arr = line.chomp.split(/\s+/)
      @mscans.push arr[0].to_i
      @nscans.push arr[1].to_i
      @edge_costs.push arr[2].to_f
      @path_costs.push arr[3].to_f
      @directions.push arr[4].to_f
    end
    @mscans.reverse!
    @nscans.reverse!
    @edge_costs.reverse!
    @path_costs.reverse!
    @directions.reverse!
  end

  def write_my_chams_file(filename)
    File.open(filename, "w") do |fh|
      ## As columns:
      #(0...@mscans.size).each do |i|
      #  fh.print @time_mscans[i].to_s + " " 
      #  fh.print @time_nscans[i].to_s + " " 
      #  fh.print @mscans[i].to_s + " " 
      #  fh.print @nscans[i].to_s + " " 
      #  fh.print @edge_costs[i].to_s + "\n" 
      #end

      # As rows:
      fh.print @time_mscans.join(" ") + "\n" 
      fh.print @time_nscans.join(" ") + "\n" 
      fh.print @mscans.join(" ") + "\n" 
      fh.print @nscans.join(" ") + "\n" 
      fh.print @edge_costs.join(" ") + "\n" 
    end
  end

end



