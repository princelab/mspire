
module MS
  class Mzml
    class DataProcessing

      attr_accessor :id, :processing_methods

      # yields self if given a block
      def initialize(id, processing_methods=[], &block)
        @id, @processing_methods = id, processing_methods
        if block
          block.call(self)
        end
      end

      def to_xml(builder)
        builder.dataProcessing( id: @id ) do |dp_n|
          processing_methods.each do |proc_method|
            proc_method.to_xml(dp_n)
          end
        end
        builder
      end

      def self.list_xml(data_processing_objs, builder)
        builder.dataProcessingList(count: data_processing_objs.size) do |proc_list_n|
          data_processing_objs.each do |data_processing_obj|
            data_processing_obj.to_xml(proc_list_n)
          end
        end
        builder
      end
    end
  end
end
