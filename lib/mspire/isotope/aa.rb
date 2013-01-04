require 'mspire/molecular_formula'


module Mspire
  class Isotope
    module AA
      # These represent counts for the individual residues (i.e., no extra H
      # and OH on the ends)
      aa_to_el_hash = {
        'A' => { :c =>3, :h =>5 , :o =>1 , :n =>1 , :s =>0 , :p =>0, :se =>0 },
        'C' => { :c =>3, :h =>5 , :o =>1 , :n =>1 , :s =>1 , :p =>0, :se =>0 },
        'D' => { :c =>4, :h =>5 , :o =>3 , :n =>1 , :s =>0 , :p =>0, :se =>0 },
        'E' => { :c =>5, :h =>7 , :o =>3 , :n =>1 , :s =>0 , :p =>0, :se =>0 },
        'F' => { :c =>9, :h =>9 , :o =>1 , :n =>1 , :s =>0 , :p =>0, :se =>0 },
        'G' => { :c =>2, :h =>3 , :o =>1 , :n =>1 , :s =>0 , :p =>0, :se =>0 },
        'I' => { :c =>6, :h =>11 , :o =>1 , :n =>1 , :s =>0 , :p =>0, :se =>0 },
        'H' => { :c =>6, :h =>7 , :o =>1 , :n =>3 , :s =>0 , :p =>0, :se =>0 },
        'K' => { :c =>6, :h =>12 , :o =>1 , :n =>2 , :s =>0 , :p =>0, :se =>0 },
        'L' => { :c =>6, :h =>11 , :o =>1 , :n =>1 , :s =>0 , :p =>0, :se =>0 },
        'M' => { :c =>5, :h =>9 , :o =>1 , :n =>1 , :s =>1 , :p =>0, :se =>0 },
        'N' => { :c =>4, :h =>6 , :o =>2 , :n =>2 , :s =>0 , :p =>0, :se =>0 },
        'O' => { :c =>12, :h =>19 , :o =>2 , :n =>3 , :s =>0 , :p =>0, :se =>0 },
        'P' => { :c =>5, :h =>7 , :o =>1 , :n =>1 , :s =>0 , :p =>0, :se =>0 },
        'Q' => { :c =>5, :h =>8 , :o =>2 , :n =>2 , :s =>0 , :p =>0, :se =>0 },
        'R' => { :c =>6, :h =>12 , :o =>1 , :n =>4 , :s =>0 , :p =>0, :se =>0 },
        'S' => { :c =>3, :h =>5 , :o =>2 , :n =>1 , :s =>0 , :p =>0, :se =>0 },
        'T' => { :c =>4, :h =>7 , :o =>2 , :n =>1 , :s =>0 , :p =>0, :se =>0 },
        'U' => { :c =>3, :h =>5 , :o =>1 , :n =>1 , :s =>0 , :p =>0, :se =>1 },
        'V' => { :c =>5, :h =>9 , :o =>1 , :n =>1 , :s =>0 , :p =>0, :se =>0 },
        'W' => { :c =>11, :h =>10 , :o =>1 , :n =>2 , :s =>0 , :p =>0, :se =>0 },
        'Y' => { :c =>9, :h =>9 , :o =>2 , :n =>1 , :s =>0 , :p =>0, :se =>0 },
      }

      # 
      FORMULAS_STR = Hash[ 
        aa_to_el_hash.map {|k,v| [k, Mspire::MolecularFormula.new(v)] }
      ]

      FORMULAS_SYM = Hash[FORMULAS_STR.map {|k,v| [k.to_sym, v] }]

      # string and symbol access of amino acid residues (amino acids are
      # accessed upper case and atoms are all lower case symbols)
      FORMULAS = FORMULAS_SYM.merge FORMULAS_STR
      
      # an alias for FORMULAS
      ATOM_COUNTS = FORMULAS
    end
  end
end
