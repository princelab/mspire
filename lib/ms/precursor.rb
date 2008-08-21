require 'arrayclass'

module MS; end 

# charge_states are the possible charge states of the precursor
# parent references a scan
#                                 0  1         2      3 
MS::Precursor = Arrayclass.new(%w(mz intensity parent charge_states)) 

class MS::Precursor

  undef :intensity
  
  def intensity
    if self[1].nil?
      if s = self[2].spectrum
        self[1] = s.intensity_at_mz(self[0])
      else
        nil   # if we didn't read in the spectra, we can't get this value!
      end
    end
    self[1]
  end

end
