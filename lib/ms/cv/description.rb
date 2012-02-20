require 'ms/cv/param'
require 'cv/description'
require 'ms/mzml/referenceable_param_group'

module MS
  module CV

    # An MS::Description is a convenient way to specify several mass spec related
    # cvParam-like objects at once. 
    #
    # examples of usage:
    #
    #     # initialize with various cv param or user params:
    #     MS::CV::Description.new( MS::CV::Param.new('MS:1244551') )
    #
    #     # MS::CV::Description[] filters all arguments through the 'param'
    #     # method which interprets arguments:
    #     MS::CV::Description['MS:1000004', ['IMS:1000042', 23], param_obj, :some_ref_param_group_id,]
    #     
    #     # or can call the param method directly 
    #     desc = MS::CV::Description.new
    #     desc.param 'MS:1000004'                       # cv param
    #     desc.param 'MS:1000042', '23', 'UO:0000108'   # cv param, value, units
    #     desc.param :jazzy_param_group_id              # an id of a ReferenceableParamGroup
    #     desc.param 'super_fast', '9999'               # an MS::User::Param (name, value)
    #
    # Note: the preferred way to deal with ReferenceableParamGroup objects
    # is to pass in the ReferenceableParamGroup object itself (although the
    # to_xml method will properly handle a ReferenceableParamGroupRef object
    # and the param method will interpret a symbol
    class Description < Array

      ACCESSION_REGEX = /^[A-Z]+:[^\s]+$/

      # calls param on each argument.
      def self.[](*args)
        list = self.new
        args.each do |arg| 
          arg.is_a?(Array) ? list.param(*arg) : list.param(arg) 
        end
        list
      end

      def initialize(*args, &block)
        super(*args)
        block.call(self) if block
      end

      # The advantage of using param is that if the first argument is a string
      # it will pass it directly to MS::CV::Param[ ].  All other arguments are
      # merely pushed onto the description array.
      #
      #     desc = MS::CV::Description.new
      #     desc.param MS::UserParam.new('name', 'value')
      #     desc.param MS::Mzml::ReferenceableParamGroup.new("happy", ...)
      #     # these are passed to MS::CV::Param[]:
      #     desc.param 'MS:1000514', 29, 'UO:0000108'
      def param(*args)
        push( 
             case args.first
             when String
               MS::CV::Param[*args]
             else
               args.first
             end
            )
      end

      # for now, assumes xml is a Nokogiri::XML::Builder object
      def to_xml(xml)
        self.each do |item| 
          if item.is_a?(MS::Mzml::ReferenceableParamGroup)
            xml.referenceableParamGroupRef(ref: item.id)
          else
            item.to_xml(xml)
          end
        end
        xml
      end
    end
  end
end
