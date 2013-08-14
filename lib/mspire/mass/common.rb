module Mspire
  module Mass
    module Common

      MONO_STR = {
        'h+' => 1.00727646677,
        'e' => 0.0005486,   # www.mikeblaber.org/oldwine/chm1045/notes/Atoms/.../Atoms03.htm
        'neutron' => 1.0086649156,
      }

      MONO_STR['h2o'] = %w(H H O).map {|el| MONO_STR[el] }.reduce(:+)
      MONO_STR['oh'] = %w(O H).map {|el| MONO_STR[el] }.reduce(:+)

      AVG_STR = {
        'h+' => 1.007276, # using Mascot_H_plus mass (is this right for AVG??)
        'e' => 0.0005486,
        'neutron' => 1.0086649156,
      }

      AVG_STR['H2O'] = %w(H H O).map {|el| AVG_STR[el] }.reduce(:+)
      AVG_STR['OH'] = %w(O H).map {|el| AVG_STR[el] }.reduce(:+)

    end
  end
end
