
require 'mspire/mass'
require 'mspire/isotope'
require 'mspire/molecular_formula'
require 'mspire/spectrum'

require 'fftw3'

module Mspire
  class Isotope
    module Distribution
      NORMALIZE = :total
    end
  end
end

module Mspire
  class MolecularFormula < Hash

    # takes any element composition (see any_to_num_elements).
    #
    # returns isotopic distribution beginning with monoisotopic peak.  It cuts
    # off when no more peaks contribute more than percent_cutoff to the total
    # distribution.  After that, normalization is performed.
    #
    # all values will be fractional.  normalize may be one of:
    #
    #     :total   normalize to the total intensity
    #     :max     normalize to the highest peak intensity
    #     :first   normalize to the intensity of the first peak 
    #             (this is typically the monoisotopic peak)
    def isotope_distribution(normalize=Mspire::Isotope::Distribution::NORMALIZE, percent_cutoff=nil, isotope_table=Mspire::Isotope::BY_ELEMENT)
      mono_dist = raw_isotope_distribution(isotope_table)

      if percent_cutoff
        total_signal = mono_dist.reduce(:+)
        cutoff_index = (mono_dist.size-1).downto(0).find do |i|
          (mono_dist[i] / total_signal) >= (percent_cutoff/100.0)
        end
        # deletes these elements
        if cutoff_index
          mono_dist.slice!((cutoff_index+1)..-1)
        else
          # no peaks pass that percent cutoff threshold!
          mono_dist = []
        end
      end

      # normalization
      norm_by =
        case normalize
        when :total
          total_signal || mono_dist.reduce(:+)
        when :max
          mono_dist.max
        when :first
          mono_dist.first
        end
      mono_dist.map do |i| 
        v = i / norm_by
        (v > 0) ? v : 0
      end
    end

    # returns a spectrum object with mass values and intensity values.
    # Arguments are passed directly to isotope_distribution.
    # the molecule has a charge, this will be used to adjust the m/z values
    # (by removing or adding electrons to the m/z and as the z)
    def isotope_distribution_spectrum(*args)
      intensities = isotope_distribution(*args)
      mono = self.map {|el,cnt| Mspire::Mass::Element::MONO[el]*cnt }.reduce(:+)
      masses = Array.new(intensities.size)
      neutron = Mspire::Mass::NEUTRON
      masses[0] = mono
      (1...masses.size).each {|i| masses[i] = masses[i-1] + neutron }
      if self.charge && self.charge != 0
        masses.map! do |mass| 
          (mass - (self.charge * Mspire::Mass::ELECTRON)) / self.charge 
        end
      end
      Mspire::Spectrum.new [masses, intensities]
    end

    # returns relative ratios from low nominal mass to high nominal mass.
    # These are *not* normalized at all.
    def raw_isotope_distribution(isotope_table=Mspire::Isotope::BY_ELEMENT)
      low_nominal = 0
      high_nominal = 0
      self.each do |el,cnt|
        isotopes = isotope_table[el]
        low_nominal += (isotopes.first.mass_number * cnt)
        high_nominal += (isotopes.last.mass_number * cnt)
      end

      ffts = self.map do |el, cnt|
        isotope_el_ar = NArray.float(high_nominal+1)
        isotope_table[el].each do |isotope|
          isotope_el_ar[isotope.mass_number] = isotope.relative_abundance
        end
        FFTW3.fft(isotope_el_ar)**cnt
      end
      FFTW3.ifft(ffts.reduce(:*)).real.to_a[low_nominal..high_nominal]
    end

  end

  class Isotope
    module Distribution
      def self.calculate(molecular_formula_like, normalize=Mspire::Isotope::Distribution::NORMALIZE, percent_cutoff=nil)
        mf = molecular_formula_like.is_a?(Mspire::MolecularFormula) ? molecular_formula_like : Mspire::MolecularFormula.from_any(molecular_formula_like)
        mf.isotope_distribution(normalize, percent_cutoff)
      end

      def self.spectrum(molecular_formula_like, normalize=Mspire::Isotope::Distribution::NORMALIZE, percent_cutoff=nil)
        mf = molecular_formula_like.is_a?(Mspire::MolecularFormula) ? molecular_formula_like : Mspire::MolecularFormula.from_any(molecular_formula_like)
        mf.isotope_distribution_spectrum(normalize, percent_cutoff)
      end
    end
  end

end
