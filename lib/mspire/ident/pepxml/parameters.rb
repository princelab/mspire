module Mspire
  module Ident
    class Pepxml
      class Parameters < Hash
        def to_xml(builder)
          self.each do |k,v|
            builder.parameter(:name => k, :value => v)
          end
        end
      end
    end
  end
end

