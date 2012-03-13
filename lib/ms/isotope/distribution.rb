
require 'ms/mass'
require 'ms/isotope'
require 'ms/molecular_formula'
require 'ms/spectrum'

require 'fftw3'

module MS
  class Isotope
    module Distribution
      NORMALIZE = :total
      PERCENT_CUTOFF = 0.001
    end
  end
end

module MS
  class MolecularFormula < Hash

    # takes any element composition (see any_to_num_elements).
    #
    # returns isotopic distribution beginning with monoisotopic peak and
    # finishing when the peak contributes less than percent_cutoff to the total
    # distribution.  Then, normalization occurs.
    #
    # all values will be fractional.  normalize may be one of:
    #
    #     :total   normalize to the total intensity
    #     :max     normalize to the highest peak intensity
    #     :low     normalize to the intensity of the lowest m/z peak 
    #             (this is typically the monoisotopic peak)
    def isotope_distribution(normalize=MS::Isotope::Distribution::NORMALIZE, percent_cutoff=MS::Isotope::Distribution::PERCENT_CUTOFF)
      mono_dist = raw_isotope_distribution
      # percent_cutoff:
      final_output = []
      sum = 0.0
      mono_dist.each do |peak|
        break if (peak / sum)*100 < percent_cutoff
        final_output << peak
        sum += peak 
      end

      # normalization
      norm_by =
        case normalize
        when :total
          sum
        when :max
          final_output.max
        when :low
          final_output.first
        end
      final_output.map {|i| i / norm_by }
    end

    # returns a spectrum object with mass values and intensity values.
    # Arguments are passed directly to isotope_distribution.
    def isotope_distribution_spectrum(*args)
      intensities = isotope_distribution(*args)
      mono = self.map {|el,cnt| MS::Mass::MONO[el]*cnt }.reduce(:+)
      masses = Array.new(intensities.size)
      neutron = MS::Mass::NEUTRON
      masses[0] = mono
      (1...masses.size).each {|i| masses[i] = masses[i-1] + neutron }
      MS::Spectrum.new [masses, intensities]
    end

    # returns relative ratios from low nominal mass to high nominal mass.
    # These are *not* normalized at all.
    def raw_isotope_distribution
      low_nominal = 0
      high_nominal = 0
      self.each do |el,cnt|
        isotopes = MS::Isotope::BY_ELEMENT[el]
        low_nominal += (isotopes.first.mass_number * cnt)
        high_nominal += (isotopes.last.mass_number * cnt)
      end

      ffts = self.map do |el, cnt|
        isotope_el_ar = NArray.float(high_nominal)
        MS::Isotope::BY_ELEMENT[el].each do |isotope|
          isotope_el_ar[isotope.mass_number] = isotope.relative_abundance
        end
        FFTW3.fft(isotope_el_ar)**cnt
      end
      FFTW3.ifft(ffts.reduce(:*)).real.to_a[low_nominal..high_nominal]
    end

  end


  class Isotope
    module Distribution
      def self.calculate(molecular_formula_like, normalize=MS::Isotope::Distribution::NORMALIZE, percent_cutoff=MS::Isotope::Distribution::PERCENT_CUTOFF)
        MS::MolecularFormula.new(molecular_formula_like).isotope_distribution(normalize, percent_cutoff)
      end

      def self.spectrum(molecular_formula_like, normalize=MS::Isotope::Distribution::NORMALIZE, percent_cutoff=MS::Isotope::Distribution::PERCENT_CUTOFF)
        MS::MolecularFormula.new(molecular_formula_like).isotope_distribution_spectrum(normalize, percent_cutoff)
      end
    end
  end

end
