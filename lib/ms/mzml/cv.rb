
module MS
  class Mzml
    class CV

      attr_accessor :id
      attr_accessor :full_name
      attr_accessor :version
      attr_accessor :uri

      def initialize(hash={})
        hash.each do |k,v|
          self.send("#{k}=", v )
        end
      end

      def to_xml(builder)
        builder.cv( id: id, fullName: full_name, version: version, :URI => uri )
      end

      # returns the builder object
      def self.cvlist_xml(cv_objs, builder)
        builder.cvList(count: cv_objs.size) do |cvlist_n|
          cv_objs.each do |cv_obj|
            cv_obj.to_xml(cvlist_n)
          end
        end
        builder
      end

      # These are derived by looking in the obo folder at the top of mspire
      IMS = self.new(id: "IMS",  full_name: "Imaging MS Ontology", version: "0.9.1", uri: "http://www.maldi-msi.org/download/imzml/imagingMS.obo")
      MS = self.new(id: 'MS', full_name: "Proteomics Standards Initiative Mass Spectrometry Ontology", version: "3.18.0", uri: "http://psidev.cvs.sourceforge.net/*checkout*/psidev/psi/psi-ms/mzML/controlledVocabulary/psi-ms.obo")
      # the version for UO doesn't really exist: seen files where they use the
      # download date: DD:MM:YYY
      UO = self.new(id: "UO", full_name: "Unit Ontology", version: "16:02:2012", uri: "http://obo.cvs.sourceforge.net/*checkout*/obo/obo/ontology/phenotype/unit.obo")

    end
  end
end
