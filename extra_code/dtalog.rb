
class DTALog
  # returns an array indexed by the dta file number (starting at 0)
  # each entry is an array [first_scan, last_scan, dta_filename_noext]
  # this is now obsolete since I found the scan # index at the end of the srf
  # files
  def self.dta_and_scans_by_dta_index(file)
    dta_index = nil
    final_scan = nil
    dta_cnt = 0
    re = /^ m/o
    scan_line_re = /scan: (\d+) - (\d+), Datafile: (.*?) (.*)/o
    other_dta_re = /Datafile: (.*?) /o
    File.open(file) do |fh|
      10.times { fh.readline }
      scan_range_line = fh.readline
      if scan_range_line =~ /scan range\s+= \d+ - (\d+)/
        # this is an overestimate (since MS scans have no dta, but that's OK)
        dta_index = Array.new($1.to_i)
      else
        dta_index = []
      end
      3.times { fh.readline }
      fh.each do |line|
        if line =~ re
          if line =~ scan_line_re
            first_scan = $1.to_i
            last_scan = $2.to_i
            the_rest = $4.dup
            dta_index[dta_cnt] = [first_scan, last_scan, $3.sub(/\.dta/,'')]
            dta_cnt += 1
            if the_rest =~ other_dta_re 
              dta_index[dta_cnt] = [first_scan, last_scan, $1.sub(/\.dta/,'')]
              dta_cnt += 1
            end
          end
          break
        end
      end
      fh.each do |line|
        if line =~ scan_line_re
          first_scan = $1.to_i
          last_scan = $2.to_i
          the_rest = $4.dup
          dta_index[dta_cnt] = [first_scan, last_scan, $3.sub(/\.dta/,'')]
          dta_cnt += 1
          if the_rest =~ other_dta_re 
            dta_index[dta_cnt] = [first_scan, last_scan, $1.sub(/\.dta/,'')]
            dta_cnt += 1
          end
        end
      end
    end
    dta_index.compact! # remove those trailing nils
    dta_index
  end
end

