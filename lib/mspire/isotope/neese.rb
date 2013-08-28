require 'mspire/isotope/nist'

module Mspire
  class Isotope
    module Neese
      RATIOS = {
        H: [0.999844, 0.000156],
        C: [0.9891, 0.0109],
        N: [0.99635, 0.00365],
        O: [0.99759, 0.00037, 0.00204],
        S: [0.9493, 0.0076, 0.0429, 0.0002]
      }

      BY_ELEMENT = Mspire::Isotope::NIST::BY_ELEMENT.dup  # shallow copy on purpose

      RATIOS.each do |el, abundances| 
        BY_ELEMENT[el] = Mspire::Isotope::NIST::BY_ELEMENT[el].
          zip(abundances).map do |isotope, abundance|
          if abundance
            new_isotope = isotope.dup
            new_isotope.relative_abundance = abundance 
            new_isotope
          else
            isotope
          end
        end
      end

      ISOTOPES = BY_ELEMENT.values.flatten(1).sort_by {|ist| [ist.atomic_number, ist.mass_number] }
    end
  end
end

