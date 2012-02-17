require 'ms/cv/describable'

module MS
  class Mzml
    class Contact
      include MS::CV::Describable
      def to_xml(builder)
        builder.contact do |fc_n|
          super(fc_n)
        end
      end
    end
  end
end
