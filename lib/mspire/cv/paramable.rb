require 'cv/param'
require 'mspire/user_param'
require 'mspire/cv/param'
require 'nokogiri'
require 'andand'

module Mspire
  module CV
    module Paramable

      attr_accessor :cv_params
      attr_accessor :user_params
      attr_accessor :ref_param_groups

      def params
        cv_params + ref_param_groups.flat_map(&:params) + user_params 
      end

      def params?
        total_num_params = cv_params.size + 
          ref_param_groups.reduce(0) {|sum,group| sum + 
            group.params.size } + user_params.size
        total_num_params > 0
      end

      def accessionable_params
        cv_params + ref_param_groups.flat_map(&:params)
      end

      #def params_by_name
      #  params.index_by &:name
      #end

      #def params_by_accession
      #  accessionable_params.index_by &:accession
      #end
      
      # returns the value if the param exists by that name.  Returns true if
      # the param exists but has no value. returns false if no param
      def fetch(name)
        param = params.find {|param| param.name == name}
        if param
          param.value || true
        else
          false
        end
      end

      def fetch_by_accession(acc)
        param = accessionable_params.find {|v| v.accession == acc }
        if param
          param.value || true
        else
          false
        end
      end
      alias_method :fetch_by_acc, :fetch_by_accession

      def param?(name)
        params.any? {|param| param.name == name }
      end

      def initialize(opts={params: []})
        @cv_params = []
        @user_params = []
        @ref_param_groups = []
        describe_many!(opts[:params])
      end

      def param_by_accession(acc)
        accessionable_params.find {|v| v.accession == acc }
      end
      alias_method :param_by_acc, :param_by_accession

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
              Mspire::CV::Param[ arg[:accession], arg[:value] ]
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
