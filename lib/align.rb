
#require 'ms/parser'
#require 'ms/parser/mzxml'
require 'ms/msrun'
require 'spec_id/proph'
require 'vec'

require 'pp'

class Align

  # Returns an array of peptides where each peptide passes threshold criteria
  # and each has been updated with scans, and dta filenames dependent on
  # matching with the basename_noext of the mztimes files.
  # Each peptide is guaranteed unique by sequence+charge
  # mztimes is an array of mzXML or .timeIndex files
  # if a peptide has no scans in the given mztimes set, it is discarded
  def peps_with_scans(mztimes, prot_xml, pep_proph_xml, prot_prob=1.0, pep_init_prob=1.0, pep_nsp_prob=1.0)

    ## Create scan indices on msrun name
    if mztimes.class != Array ; mztimes = [mztimes] end
    msrun_indices = mztimes.collect do |file| MS::MSRunIndex.new(file) end
    scanindex_by_basename_noext = {}
    msrun_indices.each do |runindex|
      scanindex_by_basename_noext[runindex.basename_noext] = runindex.scans_by_num
    end

    dta_filenames = Proph::Pep::Parser.new.dta_filenames_by_seq_charge(pep_proph_xml, "regex")

    parser = Proph::Prot::Parser.new
    parser.get_prots_and_peps(prot_xml, prot_prob, pep_init_prob, pep_nsp_prob, "regex")
    peptides = parser.peps
    peptides = Proph::Pep.uniq_by_seqcharge(peptides)
    ## we update each peptide with a list of dtafilenames
    ## then we update with a parallel list of scans (one for each dtafn...
    ## unless there are multiple scans associated with each filename
    ## in which case it will be an array
    _update_filenames(peptides, dta_filenames)
    peptides = _update_and_filter_by_scans(peptides, scanindex_by_basename_noext)
    return peptides
  end

  # takes the list of filenames for each peptide, and adds a scan
  # indexed from by scanindex
  # If keys are not in scanindex_by_basename_noext, then the scan is not
  # in the peptide!
  # if a peptide has no scans, it is not returned
  # if a filename is not recognized, it is dropped from the list
  def _update_and_filter_by_scans(peptides, scanindex_by_basename_noext)
    newpeps = []
    peptides.each do |pep|
      newfilenames = []
      pep.filenames.each do |dtafilename|
        (dtabase,first,last,charge) = dtafilename.split('.')
        if scanindex_by_basename_noext.key?(dtabase)
          newfilenames << dtafilename
          if first == last
            pep.scans << scanindex_by_basename_noext[dtabase][first.to_i]
          else
            scans = (first.to_i...last.to_i).collect do |index|
              scanindex_by_basename_noext[dtabase].scans_by_num[index]
            end
            pep.scans << scans
          end
        else
        end
      end
      pep.filenames = newfilenames
      if pep.scans.size > 0
        newpeps << pep
      end
    end
    newpeps
  end

  # takes an array of peptide arrays
  # will find the overlapping set
  # returns an array of peptide arrays
  # assumes that each pep_group is unique on sequence+charge
  def overlapping_peps_by_seqcharge(pep_groups)
    ## CREATE overlapping set:
    hashes = pep_groups.collect do |group|
      group.hash_uniq_by(:sequence, :charge)
    end
    pep_keys = hashes.collect do |hash|
      hash.collect do |k,v| k end
    end
    olapping_keys = pep_keys.inject do |olap,obj|
      olap & obj
    end
    pep_arrays = hashes.collect do |hash|
      pep_array = olapping_keys.collect do |k|
        hash[k]
      end
    end
  end

  # tosses out any peptides from pep_groups where the
  # arithmetic_avg_scan_by_parent_time.time is greater than 'deviations' from
  # the least squares regression line assumes that each peptide is parallel
  # (performed iteratively)
  def toss_outliers(pep_groups, deviations=0.0)
    arr_of_vecs = pep_groups.collect do |peps|
      time_arr = peps.collect do |pep| 
        pep.arithmetic_avg_scan_by_parent_time.time
      end
      VecD.new(time_arr)
    end

    # in the future this could be expanded for multiple dimensions
    indices = arr_of_vecs.first.outliers_iteratively(deviations, arr_of_vecs[1])

    # remove the peptides that are outliers
    #pep_groups.each do |peps| puts peps.size.to_s end
    pep_groups.each do |peps|
      indices.each do |i| peps.delete_at(i) end
    end
    #pep_groups.each do |peps| puts peps.size.to_s end
    pep_groups
  end

  # max_dups will toss out any peptides having > max_dups dtafilenames
  # Currently, this will only take 2 groups of peptides
  def overlapping_peps_by_seqcharge_with_filter(pep_groups, max_dups=nil, outlier_cutoff=0.0)
    pep_groups.collect! do |pep_group|
      pep_group.first.class.filter_by_max_dup_scans(max_dups, pep_group)
    end
    pep_groups = overlapping_peps_by_seqcharge(pep_groups)
    toss_outliers(pep_groups, outlier_cutoff)
    pep_groups
  end

  def _update_filenames(peptides, dta_filenames_by_seq_charge)
    peptides.each do |pep|
      pep.filenames = dta_filenames_by_seq_charge[[pep.sequence, pep.charge]]
    end
  end

  # Returns a hash[dtabase] -> [pep, ...]
  # Proteins must have peptides
  def _peps_by_dtabase(peptides)
    ## organize peptides based on filenames
    peptides_by_dtabase = Hash.new{|h,k| h[k] = [] }
    peptides.each do |k,pep|
      pep.filenames.each do |fn|
        file = fn.split(".")[0]
        peptides_by_file[file] << pep
      end
    end
    peptides_by_dtabase
  end


end
