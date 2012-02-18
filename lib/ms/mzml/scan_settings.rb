
require 'ms/cv/describable'

module MS
  class Mzml
    class ScanSettings
      include MS::CV::Describable

      attr_accessor :id

      def initialize(id, *params, &block)
        @id = id
        super(*params, &block)
      end

      def to_xml(builder)
        builder.scanSettings( id: @id ) do |ss_n|
          super(ss_n)
        end
        builder
      end

      # creates a scanSettingsList xml object
      def self.list_xml(scan_settings_objs, builder)
        builder.scanSettingsList(count: scan_settings_objs.size) do |ssl_n|
          scan_settings_objs.each {|scan_settings| scan_settings.to_xml(ssl_n) }
        end
        builder
      end
    end
  end
end
