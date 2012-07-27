require 'core_ext/enumerable'
require 'delegate'

module Mspire
  class Mzml

    # An IOIndexableList is the base object for SpectrumList and
    # ChromatogramList.  It's main feature is that it delegates all of its
    # duties to the array like object.
    class IOIndexableList < SimpleDelegator
      alias_method :get_delegate, :__getobj__

      attr_accessor :default_data_processing

      # a hash linking an id to the Integer index
      attr_accessor :id_to_index

      # array_like must implement #[] (with an Integer index), #each, size and length.  For example, it may be an
      # actual Array object, or it may be an IOIndex, something that behaves
      # similar to an array but is really pulling objects by reading an io
      # object.  Sets the spectrum_list attribute of array_like if it can be
      # set.
      def initialize(default_data_processing, array_like=[], id_to_index=nil)
        if array_like.respond_to?(:spectrum_list=)
          array_like.spectrum_list = self
        end
        @id_to_index = id_to_index
        @default_data_processing = default_data_processing
        __setobj__(array_like)
      end

      # for a class like <Object>List, returns :object.  So a SpectrumList
      # will return :spectrum.
      def list_type
        base = self.class.to_s.split('::').last.sub(/List$/,'')
        base[0] = base[0].downcase
        base.to_sym
      end


      # method to generate the id_to_index hash from the underlying delegated
      # object.
      def create_id_to_index!
        @id_to_index = {}
        get_delegate.each_with_index do |obj, i|
          @id_to_index[obj.id] = i
        end
        @id_to_index
      end

      # arg may be an Integer or a String (an id)
      def [](arg)
        arg.is_a?(Integer) ? get_delegate[arg] : get_delegate[ @id_to_index[arg] ]
      end

      def to_xml(builder, default_ids)
        default_ids["#{list_type}_data_processing".to_sym] = @default_data_processing.id
        xml_name = self.class.to_s.split('::').last
        xml_name[0] = xml_name[0].downcase
        builder.tag!(xml_name.to_sym, count: self.size, defaultDataProcessingRef: @default_data_processing.id) do |iol_n|
          self.each_with_index do |obj,i|
            obj.index = i unless obj.index
            obj.to_xml(iol_n, default_ids)
          end
        end
        builder
      end

    end
  end
end
