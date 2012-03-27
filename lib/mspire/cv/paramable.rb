require 'cv/param'
require 'mspire/user_param'
require 'mspire/cv/param'
require 'nokogiri'

module Mspire
  module CV
    module Paramable

      attr_accessor :cv_params
      attr_accessor :user_params
      attr_accessor :ref_param_groups

      def params
        cv_params + ref_param_groups.flat_map(&:params) + user_params 
      end

      def accessionable_params
        cv_params + ref_param_groups.flat_map(&:params)
      end

      def params_by_name
        params.index_by &:name
      end

      def params_by_accession
        accessionable_params.index_by &:accession
      end

      def initialize(opts={params: []})
        @cv_params = []
        @user_params = []
        @ref_param_groups = []
        describe_many!(opts[:params])
      end

      # cast may be something like :to_i or :to_f
      def find_param_value_by_accession(accession, cast=nil)
        param = accessionable_params.find {|v| v.accession == accession }
        if param
          val = param.value
          cast ? (val && val.send(cast)) : val
        end
      end

      def find_param_by_accession(accession)
        accessionable_params.find {|v| v.accession == accession }
      end

      def param_exists_by_accession?(accession)
        accessionable_params.any? {|v| v.accession == accession }
      end

      # takes an array of values, each of which is fed into describe!
      def describe_many!(array)
        array.each do |arg|
          if arg.is_a?(Array)
            describe!(*arg)
          else
            describe!(arg)
          end
        end
      end

      # Expects arguments describing a single CV::Param or Mapire::UserParam.
      # Will also accept an Nokogiri::XML::Node or Nokogiri::XML::NodeSet
      #
      #     obj.describe! 'MS:1000130'  # a positive scan
      #     obj.describe! CV::Param['MS:1000130']  # same behavior
      #
      #     # base peak intensity, units=number of counts
      #     obj.describe! "MS:1000505", 1524.5865478515625, 'MS:1000131'
      #
      #     # given an XML::NodeSet
      #     obj.describe! xml_node.xpath('.//cvParam')
      #
      #     # given an XML
      #     obj.describe! xml_node.xpath('.//cvParam').first
      #
      # returns self
      def describe!(*args)
        return self if args.first.nil?
        case (arg=args.first)
        when String
          @cv_params << Mspire::CV::Param[ *args ]
        when Mspire::Mzml::ReferenceableParamGroup
          @ref_param_groups << arg
        when Nokogiri::XML::Node  # a nokogiri node in particular
          param = 
            case arg.name
            when 'cvParam'
              ::CV::Param.new(arg[:cvRef], arg[:accession], arg[:name], arg[:value])
            when 'userParam'
              Mspire::UserParam.new(arg[:name], arg[:value], arg[:type])
            end
          if (unit_acc = arg[:unitAccession])
            param.unit = ::CV::Param.new(arg[:unitCvRef], unit_acc, arg[:unitName])
          end
          @cv_params << param
        when Nokogiri::XML::NodeSet
          arg.each {|node| describe!(node) }
        else
          if arg.is_a?(Mspire::UserParam)
            @user_params << arg
          else
            (@cv_params << arg) if arg
          end
        end
        self
      end

        # iterates over @params and calls .to_xml on each object.
        def to_xml(xml)
          [:ref_param_groups, :cv_params, :user_params].each do |kind|
            self.send(kind).each do |obj|
              obj.to_xml(xml)
            end
          end
          xml
        end

      end
    end
  end
