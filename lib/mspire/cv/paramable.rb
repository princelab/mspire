require 'cv/param'
require 'mspire/user_param'
require 'mspire/cv/param'
require 'nokogiri'
require 'andand'

module Mspire
  module CV

    # a module providing the method from_xml for the classes of paramable objects
    module ParamableFromXml

      def from_xml(xml, ref_hash, obj=nil)
        obj ||= self.new
        obj.describe!(xml, ref_hash)
        obj
      end

    end

    module Paramable

      attr_accessor :cv_params
      attr_accessor :user_params
      attr_accessor :ref_param_groups

      def params
        cv_params + ref_param_groups.flat_map(&:params) + user_params 
      end

      def each_param(&block)
        return enum_for __method__ unless block
        cv_params.each(&block)
        ref_param_groups.flat_map(&:params).each(&block)
        user_params.each(&block)
        nil
      end

      def params?
        total_num_params = cv_params.size + 
          ref_param_groups.reduce(0) {|sum,group| sum + 
            group.params.size } + user_params.size
        total_num_params > 0
      end

      def each_accessionable_param(&block)
        return enum_for __method__ unless block
        cv_params.each(&block)
        ref_param_groups.flat_map(&:params).each(&block)
        nil
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
        param = each_param.find {|param| param.name == name}
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
        each_accessionable_param.find {|v| v.accession == acc }
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

      # Expects arguments describing a single CV::Param or Mspire::UserParam.
      # Will also accept an Nokogiri::XML::Node of the thing that is
      # describable (meaning it has child elements of cvParam etc.)
      #
      #     obj.describe! 'MS:1000130'  # a positive scan
      #     obj.describe! CV::Param['MS:1000130']  # same behavior
      #
      #     # base peak intensity, units=number of counts
      #     obj.describe! "MS:1000505", 1524.5865478515625, 'MS:1000131'
      #
      #     # given an XML::NodeSet (and an optional hash of
      #     ReferenceableParamGroup objects indexed by id)
      #     obj.describe! xml_node, ref_param_hash
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
          xpath.children.each do |child_n|
            case child_n.name
            when 'referenceableParamGroup'
              @ref_param_groups << arg.last[child_n[:ref]]
            when 'cvParam'
              @cv_params << Mspire::CV::Param[ child_n[:accession], child_n[:value] ]
            when 'userParam'
              @user_params << Mspire::UserParam.new(child_n[:name], child_n[:value], child_n[:type])
            end
          end
            case arg.name
            when 'cvParam'
            when 'userParam'
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
