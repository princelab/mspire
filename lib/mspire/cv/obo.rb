
require 'obo/ms'
require 'obo/ims'
require 'obo/unit'

module Mspire
  module CV
    module Obo

      # a hash keyed on ID that gives the cv term name
      NAME = %w(MS IMS Unit).inject({}) do |hash,key|
        hash.merge! ::Obo.const_get(key).id_to_name 
      end
      CAST = %w(MS IMS Unit).inject({}) do |hash,key|
        hash.merge! ::Obo.const_get(key).id_to_cast
      end

    end
  end
end
