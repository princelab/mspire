require 'ms/cv/describable'

module MS
  class Mzml
    class Run
      include MS::CV::Describable

      # required
      attr_accessor :default_instrument_configuration

      # optional
      attr_accessor :default_source_file

      # required
      attr_accessor :id

      # optional
      attr_accessor :sample

      # optional
      attr_accessor :start_time_stamp

      # takes a SpectrumList object (a special array of spectra)
      attr_accessor :spectra

      # takes a ChromatogramList object (a special array of chromatograms)
      attr_accessor :chromatograms

      def initialize(id, default_instrument_configuration, *params, &block)
        super(*params, &block)
      end

      def to_xml(builder)
        atts = { id: @id, 
          defaultInstrumentConfigurationRef: @default_instrument_configuration.id
        }
        atts[:defaultSourceFileRef] = @default_source_file.id if @default_source_file
        atts[:sampleRef] = @sample.id if @sample
        atts[:startTimeStamp] = @start_time_stamp if @start_time_stamp
        
        builder.run(atts) do |run_n|
          super(run_n)
          run_n.spectrumList
        end
        builder
      end
    end
  end
end
