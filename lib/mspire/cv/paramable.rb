require 'cv/param'
require 'mspire/cv/param'
require 'nokogiri'
require 'andand'

module Mspire
  module CV
    module Paramable

      attr_accessor :cv_params

      alias_method :cv_params, :params
      alias_method :cv_params=, :params=

      def each_param(&block)
        return enum_for __method__ unless block
        cv_params.each(&block)
        ref_param_groups.flat_map(&:params).each(&block)
        user_params.each(&block)
        nil
      end

      def params?
        cv_params.size > 0 || 
          ref_param_groups.any? {|group| group.params.size > 0 } || 
          user_params.size > 0
      end

      # yields each current param.  If the return value is not false or nil,
      # it is deleted (i.e., any true value and it is deleted).  Then adds the
      # given parameter or makes a new one by accession number.
      def replace!(*describe_args, &block)
        reject!(&block).describe!(*describe_args)
      end

      # returns self
      def reject!(&block)
        cv_params.reject!(&block)
        self
      end

      def replace_many!(describe_many_arg, &block)
        reject!(&block).describe_many!(describe_many_arg)
      end

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

      # returns the value if the param exists with that accession.  Returns
      # true if the param exists but has no value. returns false if no param
      # with that accession.
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

      def initialize
        @cv_params = []
      end
      alias_method :params_init, :initialize

      def param_by_accession(acc)
        each_accessionable_param.find {|v| v.accession == acc }
      end
      alias_method :param_by_acc, :param_by_accession

      # takes an array of values, each of which is fed into describe!
      # returns self.
      def describe_many!(array)
        array.each do |arg|
          if arg.is_a?(Array)
            describe!(*arg)
          else
            describe!(arg)
          end
        end
        self
      end

      # reads the paramable nodes and returns self.  Use this if your element
      # does not have anything besides paramable elements.
      def describe_self_from_xml!(xml_node, ref_hash=nil)
        describe_from_xml!(xml_node, ref_hash)
        self
      end

      # takes a node with children that are cvParam objects 
      # returns the next child node after the paramable elements or nil if none
      def describe_from_xml!(xml_node, ref_hash=nil)
        # TODO: this was merely cleaned up from Paramable and should be
        # re-factored
        return nil unless (child_n = xml_node.child) 
        loop do
          array = 
            case child_n.name
            when 'cvParam'
              @cv_params << Mspire::CV::Param[ child_n[:accession], child_n[:value] ]
            else # assumes that the above precede any following children as per the spec
              break 
            end
          if (unit_acc = child_n[:unitAccession])
            array.last.unit = ::CV::Param.new(child_n[:unitCvRef], unit_acc, child_n[:unitName])
          end
          break unless child_n = child_n.next
        end
        child_n
      end

      # Expects arguments describing a single CV::Param
      #
      #     obj.describe! 'MS:1000130'  # a positive scan
      #     obj.describe! CV::Param['MS:1000130']  # same behavior
      #
      #     # base peak intensity, units=number of counts
      #     obj.describe! "MS:1000505", 1524.5865478515625, 'MS:1000131'
      #
      # returns self
      def describe!(*args)
        return self if args.first.nil?
        case (arg=args.first)
        when String
          @cv_params << Mspire::CV::Param[ *args ]
        else
          @cv_params << arg
        end
        self
      end

      # iterates over @params and calls .to_xml on each object.
      def to_xml(xml)
        self.cv_params.each do |obj|
          obj.to_xml(xml)
        end
        xml
      end

    end
  end
end
