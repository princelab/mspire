
module MS
  class Spectrum
    # this module can be used to extend the behavior of some peaks as desired
    module Centroidish
      def mz() first end
      def intensity() last end
    end
    # an Array implementation of Centroidish using alias_method.  Accessing
    # :mz and :intensity using this object will be nearly 2X as fast as
    # extending the Centroidish behavior (confirmed by testing)
    class Centroid < Array
      alias_method :mz, :first
      alias_method :intensity, :last
    end
  end
end
