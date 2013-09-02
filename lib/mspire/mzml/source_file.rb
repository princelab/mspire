require 'mspire/paramable'
require 'mspire/mzml/list'
require 'pathname'

module Mspire
  class Mzml
    class SourceFile
      include Mspire::Paramable
      extend Mspire::Mzml::List

      # (required) An identifier for this file.
      attr_accessor :id
      # (required) Name of the source file, without reference to location
      # (either URI or local path).
      attr_accessor :name
      # (required) URI-formatted location where the file was retrieved.
      attr_accessor :location

      # expands the path and sets the name and location.  Sets the id to the
      # basename.
      def self.[](path, opts={})
        (name, path) = uri_basename_and_path(path)
        self.new(name, name, path)
      end

      # takes a filename (with a relative or expanded path) and returns the
      # uri basename and path suitable for mzml files
      def self.uri_basename_and_path(file)
        pathname = Pathname.new(file)
        dir = pathname.expand_path.dirname.to_s
        dir = '/'+dir unless (dir[0] == '/')
        [pathname.basename, 'file://'+ dir]
      end

      def initialize(id="sourcefile1", name="mspire-simulated", location='file://')
        @id, @name, @location = id, name, location
        params_init
        yield(self) if block_given?
      end

      def to_xml(builder)
        builder.sourceFile( id: @id, name: @name, location: @location ) do |sf_n|
          super(sf_n)
        end
        builder
      end

      def self.from_xml(xml, ref_hash)
        self.new(xml[:id], xml[:name], xml[:location]).describe_self_from_xml!(xml, ref_hash)
      end

    end
  end
end
