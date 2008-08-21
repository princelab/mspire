require 'validator'

require 'set'
require 'group_by'
require 'shuffle'

# calculates protein hit precision based on peptide precision
class Validator::ProtFromPep < Validator

  # calculate protein precision based on the number of false peptides
  # returns the precision based on the number of proteins *completely false*
  # calculates the worst precision by assuming that proteins with the fewest
  # peptides are all false (before prots with more pephits)
  # note that this approaches the worst, but is not guaranteed to be worst
  # unless each pephit maps to a single protein hit.
  # [worst, normal_mean, normal_stddev]
  # options
  #    :num_its_normal => Integer, # num iterations for normal (d: 10)
  #    :num_its_worstcase => Integer, # num iterations for worstcase (d: 10)
  #
  def prothit_precision(peps, num_false_pephits, opts={})
    opts[:num_its_normal] ||= 10
    opts[:num_its_worstcase] ||= 10
    # get the num_peps_per_protein array
    worst = worstcase_prothit_precision(peps, num_false_pephits, :num_its => opts[:num_its_worstcase])
    (normal_mean, normal_stdev) = normal_prothit_precision( peps, num_false_pephits, :num_its => opts[:num_its_normal])
    [worst, normal_mean, normal_stdev]
  end

  # returns an array of the number of peptide hits in each protein
  def num_peps_per_protein(peps)
    num_pephits_by_prot = Hash.new { 0 }
    peps.each do |pep|
      pep.prots.each do |prot|
        num_pephits_by_prot[prot.reference] += 1
      end
    end
    num_pephits_by_prot.values
  end

  # returns the worstcase precision.  This assumes that every small protein
  # with the fewest peptide hits is completely 'filled' with incorrect hits in
  # preference to any higher hit protein.  
  # Where each peptide hit maps to a single protein, this is guaranteed to be
  # worst-case.  If this doesn't hold, there are some extreme cases where a
  # poorer precision could be generated, but this is still probably fairly
  # close.  Thus, a slightly different answer may be generated each time.
  # ...variation is produced by shuffling the order of the proteins from which
  # peptides are removed within groups of proteins having the same number of
  # peptides.
  # This method does NOT require that the prothits be updated to reflect only
  # those pephits being passed in.
  #
  #   validator.worstcase_prothit_precision(peps, 14, 1) # => 0.232111
  #
  # options:
  #   :num_its => Integer (default: 10) number of times to run (finds minimum)
  #   :one_prot_per_pep => true | *false   assumes each peptide maps to a
  #                                        single protein
  def worstcase_prothit_precision(peps, num_false_pephits, opts = {})
    num_its = opts[:num_its] || 10
    one_prot_per_pep = opts[:one_prot_per_pep]  # nil or false still == false
    one_prot_per_pep = false if one_prot_per_pep == nil
    

    ##############################################
    # The END Cases (can be dealt with quickly)
    ##############################################
    if num_false_pephits == 0
      return 1.0
    elsif num_false_pephits >=  peps.size
      return 0.0
    end

    if one_prot_per_pep
      num_peps_per_prot = num_peps_per_protein(peps)
      return worstcase_prothit_precision_by_numbers(num_peps_per_prot, num_false_pephits)
    else
      #####################################
      # HERE's the basic plan!!
      #####################################
      # order the proteins by num peptides
      # create a set of peptides
      # delete peptides from the proteins off the set o' peptides (ensuring that
      # a deleted one cannot be deleted twice)

      #####################################
      # order the proteins by num peptides
      # and create a hash that holds the peptides (given here) in those proteins
      prots_to_peps_here = Hash.new {|h,k| h[k] = [] }
      prots_to_peps_size = Hash.new { 0 }
      pep_ids = []
      pep_ids_to_prot_ids = Hash.new {|h,k| h[k] = [] }
      peps.each do |pep|
        #puts pep.prots.size
        pep.prots.each do |prot|
          #p prot.reference
          prots_to_peps_here[prot] << pep
          prots_to_peps_size[prot] += 1
          pep_ids << pep
          pep_ids_to_prot_ids[pep] << prot
        end
      end
      prot_ids_listed_by_peps_size = prots_to_peps_size.keys
      tot_num_prots = prot_ids_listed_by_peps_size.size

      sample = Array.new(num_its)

      srand( 777 )
      precision_sample = (0...num_its).to_a.map do
        num_false_pephits_counter = num_false_pephits
        # create a set of peptides
        pep_ids_set = pep_ids.to_set
        # shuffle the proteins within size groups
        finished = false
        prot_ids_listed_by_peps_size.group_by {|prot_id| prots_to_peps_size[prot_id] }.sort.each do |k,group_of_proteins_with_same_pep_size|
          group_of_proteins_with_same_pep_size.shuffle!
          group_of_proteins_with_same_pep_size.each do |prot_id|
            prots_to_peps_here[prot_id].each do |pep_id|
              if pep_ids_set.include?(pep_id)  # if 1
                # remove a peptide
                pep_ids_set.delete(pep_id)
                num_false_pephits_counter -= 1
                if num_false_pephits_counter == 0  # if 2
                  finished = true
                end                                # close if 2
              end                                  # close if 1
              break if finished  # each pep
            end
            break if finished  # each prot
          end
          break if finished  # each group_of_proteins_with_same_pep_size
        end # each group_of_proteins_with_same_pep_size
        ## Figure out the number of proteins left!
        proteins_still_around = pep_ids_set.inject(Set.new) {|protset,pep_id| protset.merge( pep_ids_to_prot_ids[pep_id]) }

        proteins_still_around.size.to_f / tot_num_prots
      end # a sample
      return precision_sample.min
    end # FINAL else
  end

  # returns the precision of the worst possible outcome
  def worstcase_prothit_precision_by_numbers(num_peps_per_prot, num_false_pephits)
    completely_false_proteins = 0
    num_peps_per_prot.sort.each do |num_peps|
      num_false_pephits -= num_peps
      if num_false_pephits >= 0
        completely_false_proteins += 1
      end
      if num_false_pephits <= 0
        break
      end
    end
    num_prots = num_peps_per_prot.size
    (num_prots - completely_false_proteins).to_f/num_prots
  end

  # normal as in a standard normal distribution of peptide hits per protein
  # they are distributed randomly and the precision is assumed to take on a
  # standard normal distribution.
  # num_peps_per_protein is an array of the number of peptides per protein hit
  # (these are the true hits)
  # assumes that the number follows a gaussian distribution (binomial
  # distributions tend toward gaussians, I believe, at large N)
  # returns [mean_precision, stdev_precision]
  # options:
  #   :num_its => Integer (default: 10)
  #
  # if num_iterations is set at 1, then only the precision will be returned
  # though random, the same seed is always used to start this process, meaning
  # that the same results will be produced on consecutive attempts.
  #
  #   validator.normal_prothit_precision(peps, 13, :num_its => 1) # -> 0.95433
  #   validator.normal_prothit_precision(peps, 13, :num_its => 2) # -> [0.92002, 1.2223]
  def normal_prothit_precision( peps, num_false_pephits, opts={})
    num_iterations = opts[:num_its] || 10
    srand( 38272 )

    ##############################################
    # The END Cases (can be dealt with quickly)
    ##############################################
    if num_false_pephits == 0
      if num_iterations == 1
        return 1.0
      else
        return [1.0, 0.0] 
      end
    elsif num_false_pephits >=  peps.size
      if num_iterations == 1
        return 0.0
      else
        return [0.0, 0.0]
      end
    end

    ##############################################
    # Everything else:
    ##############################################

    sample = Array.new(num_iterations)
    base_indices = (0...(peps.size)).to_a
    ### ACUTALLY, I THINK WE WANT TO CREATE AND MERGE!!!!
    # This would mean that only a single hit would validate the protein
    # if we are subtracting, then we lose the protein on a single peptide!!!!
    prot_id_set = peps.inject(Set.new) do |prtset, pep|
      prtset.merge( pep.prots.map {|prot| prot } )
    end

    tot_num_prots = prot_id_set.size
    # could also merge off the good indices
    # TODO: we should optimize based on how many false pephits given...
    
    precision_sample = (0...num_iterations).to_a.map do
      shuffled_indices = base_indices.map
      shuffled_indices.shuffle!
      good_indices = shuffled_indices[num_false_pephits..-1] 
      still_remaining = Set.new
      
      peps.values_at(*good_indices).each do |pep| 
        still_remaining.merge(pep.prots.map {|prot| prot })
      end
      still_remaining.size.to_f / tot_num_prots
    end
    if num_iterations == 1
      precision_sample.shift
    else
      #puts "PRECISION GROUP: "
      #p precision_sample
      sample_stats(precision_sample)
    end
  end
end

