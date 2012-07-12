require 'mspire/cv/paramable'

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

      def self.from_xml(xml, ref_hash, io_index_list, instrument_config_hash, data_processing_hash)
        obj = self.new(xml[:id], instrument_config_hash[xml[:defaultInstrumentConfigurationRef]])
        (list_node = obj.describe_from_xml!(xml, ref_hash)) || return obj
        loop do
          start_time = Time.now
          io_index = io_index_list.find {|io_index| io_index.name.to_s == list_node.name }
          list_class = Mspire::Mzml.const_get(io_index.name.to_s.capitalize + "List")
          list_obj = list_class.new(data_processing_hash[list_node[:defaultDataProcessingRef]], io_index)
          self.send(io_index.name.to_s + "_list=", list_obj)
          puts "TIME TO READ HEADER: #{Time.now - start_time}"
          break unless list_node = list_node.next
        end
      end
    end
  end
end
