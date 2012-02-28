require 'ms/spectrum_like'
require 'bsearch'
require 'bin'
require 'ms/peak'

module MS
  # note that a point is an [m/z, intensity] doublet.
  # A peak is considered a related string of points
  class Spectrum
    include MS::SpectrumLike

    DEFAULT_MERGE = {
      :bin_width => 5,
      :bin_unit => :ppm,
      :normalize => true,
      :return_data => false,
      :split => :share
    }

    class << self

      def from_points(ar_of_doublets)
        _mzs = []
        _ints = []
        ar_of_doublets.each do |mz, int|
          _mzs << mz
          _ints << int
        end
        self.new([_mzs, _ints])
      end


      # returns a new spectrum which has been merged with the others.  If the
      # spectra are centroided (just checks the first one and assumes the others
      # are the same) then it will bin the points (bin width determined by
      # opts[:resolution]) and then segment according to monotonicity (sharing
      # intensity between abutting points).  The  final m/z is the weighted
      # averaged of all the m/z's in each peak.  Valid opts (with default listed
      # first):
      #
      #     :bin_width => 5 
      #     :bin_unit => :ppm | :amu        interpret bin_width as ppm or amu
      #     :bins => array of Bin objects   for custom bins (overides other bin options)
      #     :normalize => false             if true, divides total intensity by 
      #                                     number of spectra
      #     :return_data => false           returns a parallel array containing
      #                                     the peaks associated with each returned point
      #     :split => false | :share | :greedy_y   see MS::Peak#split
      #
      # The binning algorithm is the fastest possible algorithm that would allow
      # for arbitrary, non-constant bin widths (a ratcheting algorithm O(n + m))
      def merge(spectra, opts={})
        opt = DEFAULT_MERGE.merge(opts)
        (spectrum, returned_data) =  
          unless spectra.first.centroided? == false
            # find the min and max across all spectra
            first_mzs = spectra.first.mzs
            min = first_mzs.first ; max = first_mzs.last
            spectra.each do |spectrum| 
              mzs = spectrum.mzs
              min = mzs.first if mzs.first < min
              max = mzs.last if mzs.last > max
            end

            # Create Bin objects
            bins = 
              if opt[:bins]
                opt[:bins]
              else
                divisions = []
                bin_width = opt[:bin_width]
                use_ppm = (opt[:bin_unit] == :ppm)
                current_mz = min
                loop do
                  if current_mz >= max
                    divisions << max
                    break
                  else
                    divisions << current_mz
                    current_mz += ( use_ppm ? current_mz./(1e6).*(bin_width) : bin_width )
                  end
                end
                # make each bin exclusive so there is no overlap
                bins = divisions.each_cons(2).map {|pair| Bin.new(*pair, true) }
                # make the last bin *inclusive* of the terminating value
                bins[-1] = Bin.new(bins.last.begin, bins.last.end)
                bins
              end

            spectra.each do |spectrum|
              Bin.bin(bins, spectrum.points, &:first)
            end

            pseudo_points = bins.map do |bin|
              #int = bin.data.reduce(0.0) {|sum,point| sum + point.last }.round(3)   # <- just for info:
              [bin, bin.data.reduce(0.0) {|sum,point| sum + point.last }]
            end

            #p_mzs = [] 
            #p_ints = [] 
            #p_num_points = [] 
            #pseudo_points.each do |psp|
            #  p_mzs << ((psp.first.begin + psp.first.end)/2)
            #  p_ints << psp.last
            #  p_num_points <<  psp.first.data.size
            #end

            #File.write("file_#{opt[:bin_width]}_to_plot.txt", [p_mzs, p_ints, p_num_points].map {|ar| ar.join(' ') }.join("\n"))
            #abort 'here'


            peaks = MS::Peak.new(pseudo_points).split(opt[:split])

            return_data = []
            _mzs = [] ; _ints = []

            #p peaks[97]
            #puts "HIYA"
            #abort 'here'

            peaks.each_with_index do |peak,i|
              #peaks.each do |peak|
              tot_intensity = peak.map(&:last).reduce(:+)
              return_data_per_peak = [] if opt[:return_data]
              weighted_mz = 0.0
              peak.each do |point|
                pre_scaled_intensity = point[0].data.reduce(0.0) {|sum,v| sum + v.last }
                post_scaled_intensity = point[1]
                # some peaks may have been shared.  In this case the intensity
                # for that peak was downweighted.  However, the actually data
                # composing that peak is not altered when the intensity is
                # shared.  So, to calculate a proper weighted avg we need to
                # downweight the intensity of any data point found within a bin
                # whose intensity was scaled.
                correction_factor = 
                  if pre_scaled_intensity != post_scaled_intensity
                    post_scaled_intensity / pre_scaled_intensity
                  else
                    1.0
                  end

                return_data_per_peak.push(*point[0].data) if opt[:return_data]

                point[0].data.each do |lil_point|
                  weighted_mz += lil_point[0] * ( (lil_point[1].to_f * correction_factor) / tot_intensity)
                end
              end
              return_data << return_data_per_peak if opt[:return_data]
              _mzs << weighted_mz
              _ints << tot_intensity
            end
            [Spectrum.new([_mzs, _ints]), return_data]
          else
            raise NotImplementedError, "the way to do this is interpolate the profile evenly and sum"
          end

        if opt[:normalize]
          sz = spectra.size
          spectrum.intensities.map! {|v| v.to_f / sz }
        end
        if opt[:return_data]
          $stderr.puts "returning spectrum (#{spectrum.mzs.size}) and data" if $VERBOSE
          [spectrum, return_data]
        else
          $stderr.puts "returning spectrum (#{spectrum.mzs.size})" if $VERBOSE
          spectrum
        end
      end

    end
  end
end




