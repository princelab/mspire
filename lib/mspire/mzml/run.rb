require 'mspire/cv/paramable'
require 'mspire/mzml/io_index'
require 'mspire/mzml/spectrum_list'
require 'mspire/mzml/chromatogram_list'

module Mspire
  class Mzml
    class Run
      include Mspire::CV::Paramable

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

      # a SpectrumList object (a special array of spectra)
      attr_accessor :spectrum_list

      # takes a ChromatogramList object (a special array of chromatograms)
      attr_accessor :chromatogram_list

      # yields self if given a block
      def initialize(id, default_instrument_configuration)
        @id = id
        @default_instrument_configuration = default_instrument_configuration
        params_init
        yield(self) if block_given?
      end

      def to_xml(builder)
        atts = { id: @id,
          defaultInstrumentConfigurationRef: @default_instrument_configuration.id
        }
        atts[:defaultSourceFileRef] = @default_source_file.id if @default_source_file
        atts[:sampleRef] = @sample.id if @sample
        atts[:startTimeStamp] = @start_time_stamp if @start_time_stamp

        default_ids = { instrument_configuration: @default_instrument_configuration.id }
        
        builder.run(atts) do |run_n|
          super(run_n)
          spectrum_list.to_xml(run_n, default_ids) if spectrum_list
          chromatogram_list.to_xml(run_n, default_ids) if chromatogram_list
        end
        builder
      end

      # expects link to have the following keys:
      #
      #     :ref_hash
      #     :instrument_config_hash
      #     :source_file_hash
      #     :sample_hash
      #     :data_processing_hash
      #     :spectrum_default_data_processing
      #     :chromatogram_default_data_processing
      #     :index_list
      def self.from_xml(io, xml, link)

        # expects that the DataProcessing objects to link to have *already* been
        # parsed (parse the defaultDataProcessingRef's after grabbing the
        # index, then grab the DataProcessing object associated with that id).
        
        obj = self.new(xml[:id], 
          link[:instrument_configuration_hash][xml[:defaultInstrumentConfigurationRef]]
        )
        obj.start_time_stamp = xml[:startTimeStamp]

        link[:default_instrument_configuration] = obj.default_instrument_configuration

        # two optional object refs
        if def_source_ref=xml[:defaultSourceFileRef]
          obj.default_source_file = link[:source_file_hash][def_source_ref]
        end
        if sample_ref=xml[:sampleRef]
          obj.sample = link[:sample_hash][sample_ref]
        end

        obj.describe_from_xml!(xml, link[:ref_hash])

        index_list = link[:index_list]
        [:spectrum, :chromatogram].each do |list_type|
          next unless (byte_index = index_list[list_type])

          io_index = IOIndex.new(io, byte_index, link)

          list_obj = Mspire::Mzml.const_get(list_type.to_s.capitalize + "List")
            .new(link["#{list_type}_default_data_processing".to_sym], 
                 io_index, 
                 Hash[byte_index.ids.each_with_index.map.to_a]
                )

          obj.send(list_type.to_s + "_list=", list_obj)
        end
        obj
      end
    end
  end
end
