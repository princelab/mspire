

# inverse from Tilo Sloboda (now in facets)

class Hash
  def inverse
    i = Hash.new
    self.each_pair do |k,v|
      if (Array === v) ; v.each{ |x| i[x] = ( i.has_key?(x) ? [k,i[x]].flatten : k ) }
      else ; i[v] = ( i.has_key?(v) ? [k,i[v]].flatten : k ) end
    end ; i  
  end
end


