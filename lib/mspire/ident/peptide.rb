module Mspire ; end
module Mspire::Ident ; end

# A 'sequence' is a notation of a peptide that includes the leading and
# trailing amino acid after cleavage (e.g., K.PEPTIDER.E or -.STARTK.L )
# and may contain post-translational modification information.
#
# 'aaseq' is the amino acid sequence of just the peptide with no leading or
# trailing notation (e.g., PEPTIDER or LAKKLY)
module Mspire::Ident::Peptide
  Nonstandard_AA_re = /[^A-Z\.\-]/
  
  class << self

    # Takes a peptide sequence of the form '-.PEPTIDE.R', removes non-standard
    # amino acids, and returns the center piece
    def sequence_to_aaseq(sequence)
      after_removed = remove_non_amino_acids(sequence)
      pieces = after_removed.split('.') 
      case pieces.size
      when 3
        pieces[1]
      when 2
        if pieces[0].size > 1  ## N termini
          pieces[0]
        else  ## C termini
          pieces[1]
        end
      when 1  ## this must be a parse error!
        pieces[0] ## which is the peptide itself  
      else
        abort "bad peptide sequence: #{sequence.inspect}"
      end
    end

    # removes non standard amino acids specified by Nonstandard_AA_re
    def remove_non_amino_acids(sequence)
      sequence.gsub(Nonstandard_AA_re, '')
    end

    # remove non amino acids and split the sequence
    def prepare_sequence(sequence)
      nv = remove_non_amino_acids(sequence)
      split_sequence(nv)
    end

    # Returns prev, peptide, next from sequence.  Parse errors return
    # nil,nil,nil
    #   R.PEPTIDE.A  # -> R, PEPTIDE, A
    #   R.PEPTIDE.-  # -> R, PEPTIDE, -
    #   PEPTIDE.A    # -> -, PEPTIDE, A
    #   A.PEPTIDE    # -> A, PEPTIDE, -
    #   PEPTIDE      # -> nil,nil,nil
    def split_sequence(sequence)
      pieces = sequence.split('.') 
      case pieces.size
      when 3
        pieces
      when 2
        if pieces[0].size > 1  ## N termini
          ['-', pieces[0], pieces[1]]
        else  ## C termini
          [pieces[0], pieces[1], '-']
        end
      when 1  ## this must be a parse error!
        [nil,nil,nil]
      when 0
        [nil,nil,nil]
      end
    end
  end
end
