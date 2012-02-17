require 'ms/mzml/file_content'
require 'ms/mzml/source_file'
require 'ms/mzml/contact'

module MS
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

      def initialize(file_content, source_files=[], contacts=[])
        @file_content, @source_files, @contacts = file_content, source_files, contacts
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
