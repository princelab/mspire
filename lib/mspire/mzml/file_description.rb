require 'mspire/mzml/file_content'
require 'mspire/mzml/source_file'
require 'mspire/mzml/contact'

module Mspire
  class Mzml
    class FileDescription

      # a summary of the different types of spectra, must be present
      attr_accessor :file_content

      # may or may not be present
      attr_accessor :source_files

      # zero to many (just listed in the singular, not enclosed in a list)
      #
      #     <contact>
      #     </contact>
      #     <contact>
      #     </contact>
      attr_accessor :contacts

      # hands the user the object if given a block
      def initialize(file_content=nil, source_files=[], contacts=[], &block)
        @file_content, @source_files, @contacts = file_content, source_files, contacts
        block.call(self) if block
        #raise ArgumentError, "FileDescription must have file_content" unless @file_content
      end

      def self.from_xml(xml)
        self.new
      end

      def to_xml(builder)
        builder.fileDescription do |fd_n|
          @file_content.to_xml(fd_n)
          if source_files.size > 0
            fd_n.sourceFileList(count: source_files.size) do |sf_n|
              source_files.each do |sf|
                sf.to_xml(sf_n)
              end
            end
          end
          contacts.each do |contact|
            contact.to_xml(fd_n)
          end
        end
      end
    end
  end
end
