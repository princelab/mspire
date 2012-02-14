module MS
  module Mass

    # takes a molecular formula in this format: C2BrH12O
    def self.formula_to_exact_mass(formula)
      # TODO: add other input methods
      pairs = formula.scan(/([A-Z][a-z]?)(\d*)/).map do |match|
        if match.last == ''
          match[-1] = 1
        end
        [match[0], match[1].to_i]
      end
      pairs.map do |pair|
        MONO[pair.first.downcase] * pair.last
      end.reduce(:+)
    end

    ELECTRON = 0.0005486 # www.mikeblaber.org/oldwine/chm1045/notes/Atoms/.../Atoms03.htm
    H_PLUS = 1.00727646677
    #  + http://www.unimod.org/masses.html
    MONO_STR = {
      'c' => 12.0,  # +
      'br' => 78.9183361,  # +
      'd' => 2.014101779,  # +
      'f' => 18.99840322,  # +
      'n' => 14.003074,  # +
      'o' => 15.99491463,  # +
      'na' => 22.9897677,  # +
      'p' => 30.973762,  # +
      's' => 31.9720707,  # +
      'li' => 7.016003,  # +
      'cl' => 34.96885272,  # +
      'k' => 38.9637074,  # +
      'si' => 27.9769265325, # http://physics.nist.gov/cgi-bin/Compositions/stand_alone.pl?ele=Si&ascii=html&isotype=some
      'i' => 126.904473,  # +
      'h+' => 1.00727646677,
      'h' => 1.007825035,  # +
      'h2o' => 18.0105647,
      'oh' => 17.002739665,
      'e' => 0.0005486,
      'se' => 79.9165196
    }
    AVG_STR = {
      'h+' => 1.007276, # using Mascot_H_plus mass (is this right for AVG??)
      'h' => 1.00794,
      'h2o' => 18.01528, 
      'oh' => 17.00734,
    }
    # sets MONO_STR, MONO, AVG_STR, and AVG
    %w(MONO AVG).each do |type|
      const_set "#{type}_SYM", Hash[ const_get("#{type}_STR").map {|k,v| [k.to_sym, v] } ]
      const_set type, const_get("#{type}_STR").merge( const_get("#{type}_SYM") )
    end
  end
end


