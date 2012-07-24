
module Mspire
  class Mzml
    class CV
      # note: CV is NOT paramable!

      # (required) The short label to be used as a reference tag with which to refer to
      # this particular Controlled Vocabulary source description (e.g., from
      # the cvLabel attribute, in CVParamType elements).
      attr_accessor :id
      # (required) The usual name for the resource (e.g. The PSI-MS Controlled Vocabulary).
      attr_accessor :full_name
      # (required) The URI for the resource.
      attr_accessor :uri
      # (optional) The version of the CV from which the referred-to terms are drawn.
      attr_accessor :version

      def initialize(id, full_name, uri, version=nil)
        @id, @full_name, @uri, @version = id, full_name, uri, version
      end

      def to_xml(builder)
        atts = {id: @id, fullName: @full_name, :URI => @uri}
        atts[:version] = @version if @version
        builder.cv( atts )
        builder
      end

      def self.list_xml(objs, builder)
        # we don't extend Mzml::List because of custom name below
        builder.cvList(count: objs.size) do |cvl_n|
          objs.each {|obj| obj.to_xml(cvl_n) }
        end
        builder
      end

      def self.from_xml(xml)
        self.new(xml[:id], xml[:fullName], xml[:URI], xml[:version])
      end

      IMS = self.new("IMS",  "Imaging MS Ontology", "http://www.maldi-msi.org/download/imzml/imagingMS.obo", "0.9.1")
      MS = self.new('MS', "Proteomics Standards Initiative Mass Spectrometry Ontology", "http://psidev.cvs.sourceforge.net/*checkout*/psidev/psi/psi-ms/mzML/controlledVocabulary/psi-ms.obo", "3.29.0")
      # the version for UO doesn't really exist: seen files where they use the
      # download date: DD:MM:YYY.  I'm going to use the save date in the header.
      UO = self.new("UO", "Unit Ontology", "http://obo.cvs.sourceforge.net/*checkout*/obo/obo/ontology/phenotype/unit.obo", "12:10:2011")

      DEFAULT_CVS = [MS, UO, IMS]

    end
  end
end
