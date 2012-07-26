require 'mspire/cv/paramable'

module Mspire
  class Mzml

    # MAY supply a *child* term of MS:1000510 (precursor activation attribute) one or more times
    #
    #     e.g.: MS:1000045 (collision energy)
    #     e.g.: MS:1000138 (percent collision energy)
    #     e.g.: MS:1000245 (charge stripping)
    #     e.g.: MS:1000412 (buffer gas)
    #     e.g.: MS:1000419 (collision gas)
    #     e.g.: MS:1000509 (activation energy)
    #     e.g.: MS:1000869 (collision gas pressure)
    #
    # MUST supply term MS:1000044 (dissociation method) or any of its children one or more times
    #
    #     e.g.: MS:1000133 (collision-induced dissociation)
    #     e.g.: MS:1000134 (plasma desorption)
    #     e.g.: MS:1000135 (post-source decay)
    #     e.g.: MS:1000136 (surface-induced dissociation)
    #     e.g.: MS:1000242 (blackbody infrared radiative dissociation)
    #     e.g.: MS:1000250 (electron capture dissociation)
    #     e.g.: MS:1000262 (infrared multiphoton dissociation)
    #     e.g.: MS:1000282 (sustained off-resonance irradiation)
    #     e.g.: MS:1000422 (high-energy collision-induced dissociation)
    #     e.g.: MS:1000433 (low-energy collision-induced dissociation)
    #     et al.
    class Activation
      include Mspire::CV::Paramable

      def to_xml(builder)
        builder.activation {|xml| super(xml) }
      end
    end
  end
end
