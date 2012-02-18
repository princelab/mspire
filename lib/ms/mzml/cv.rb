
module MS
  class Mzml
    class CV

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

      # creates a cvList and returns the builder object
      def self.list_xml(cv_objs, builder)
        builder.cvList(count: cv_objs.size) do |cvlist_n|
          cv_objs.each do |cv_obj|
            cv_obj.to_xml(cvlist_n)
          end
        end
        builder
      end

      # These are derived by looking in the obo folder at the top of mspire
      IMS = self.new("IMS",  "Imaging MS Ontology", "http://www.maldi-msi.org/download/imzml/imagingMS.obo", "0.9.1")
      MS = self.new('MS', "Proteomics Standards Initiative Mass Spectrometry Ontology", "http://psidev.cvs.sourceforge.net/*checkout*/psidev/psi/psi-ms/mzML/controlledVocabulary/psi-ms.obo", "3.18.0")
      # the version for UO doesn't really exist: seen files where they use the
      # download date: DD:MM:YYY
      UO = self.new("UO", "Unit Ontology", "http://obo.cvs.sourceforge.net/*checkout*/obo/obo/ontology/phenotype/unit.obo", "16:02:2012")

      DEFAULT_CVS = [MS, UO, IMS]

    end
  end
end
