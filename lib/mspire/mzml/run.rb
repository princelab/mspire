require 'mspire/cv/paramable'
require 'mspire/mzml/io_index'

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
      def initialize(id, default_instrument_configuration, opts={params: []}, &block)
        @id = id
        @default_instrument_configuration = default_instrument_configuration
        super(opts)
        block.call(self) if block
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
          spectrum_list.to_xml(run_n) if spectrum_list
          chromatogram_list.to_xml(run_n) if chromatogram_list
        end
        builder
      end

      def self.from_xml(io, xml, ref_hash, index_list, instrument_config_hash, source_file_hash, sample_hash, default_data_processing_hash)

        # expects that the DataProcessing objects to link to have *already* been
        # parsed (parse the defaultDataProcessingRef's after grabbing the
        # index, then grab the DataProcessing object associated with that id).
        
        obj = self.new(xml[:id], instrument_config_hash[xml[:defaultInstrumentConfigurationRef]])
        obj.start_time_stamp = xml[:startTimeStamp]

        # two optional object refs
        obj.default_source_file = source_file_hash[xml[:defaultSourceFileRef]]
        obj.sample = sample_hash[xml[:sampleRef]]

        obj.describe_from_xml!(xml, ref_hash)

        [:spectrum, :chromatogram].each do |list_type|
          io_index = IOIndex.new(io, index_list[list_type])
          list_obj = Mspire::Mzml.const_get(list_type.to_s.capitalize).new(default_data_processing_hash[list_type], io_index)
          obj.send(list_type.to_s + "_list=", list_obj)
        end
        obj
      end
    end
  end
end
