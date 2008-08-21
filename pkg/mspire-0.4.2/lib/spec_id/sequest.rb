require 'spec_id/sequest/params'
require 'hash_by'
require 'sort_by_attributes.rb'

module Sequest

  # returns one array of peptide hits:  indexes hits based on index_by, takes
  # the uniq ones and then sorts the group by sort_by (compatible with
  # sort_by_attributes) then slices from first_index to last_index
  # (inclusive).
  def self.other_hits(peps, first_index=1, last_index=9, index_by=[:base_name, :first_scan, :charge], sort_by=[:xcorr, {:down => :xcorr}])
    all_hits = []
    peps.hash_by(*index_by).each do |scan_key, peps_per_scan|
      if peps_per_scan.size >= (first_index + 1)
        all_hits.push( *(peps_per_scan.uniq.sort_by_attributes(*sort_by)[first_index..last_index]) )
      end
    end
    all_hits.compact
  end

  def self.other_hits_sorted_by_xcorr(peps, first_index, last_index, index_by=[:base_name, :first_scan, :charge])
    all_hits = []
    peps.hash_by(*index_by).each do |scan_key, peps_per_scan|
      if peps_per_scan.size >= (first_index + 1)
        all_hits.push( *(peps_per_scan.uniq.sort_by {|x| x.xcorr }.reverse[first_index..last_index]) )
      end
    end
    all_hits.compact

  end

end

