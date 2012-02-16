
require 'cv'
require 'obo/ms'
require 'obo/ims'
require 'obo/unit'

module MS
  module CV
    Obo = {
      'MS' => Obo::MS.id_to_name,
      'IMS' => Obo::IMS.id_to_name,
      'UO' => Obo::Unit.id_to_name,
    }
  end
end

