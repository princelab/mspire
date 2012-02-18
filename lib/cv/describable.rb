require 'cv/describable'
require 'nokogiri'

module CV
  module Describable
    # a CV::Description-like object (which is an array with some extra kick)
    attr_accessor :description

    def initialize(*param_objs, &block)
      description = CV::Description.new( param_objs )
      description.instance_eval &block if block
    end

    def to_xml(builder)
      description.to_xml(builder) if description
    end
  end
end
