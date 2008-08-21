
module SpecID::Pep

  # filter must be a hash with these keys allowed:
  # :xcorr1, :xcorr2, :xcorr3, :deltacn, :ppm, :include_deltacnstar
  def pass_filters?(filter)
    filter.all? do |k,v| 
      k_as_s = k.to_s
      if ((k_as_s[0...-1] == 'xcorr') and (k.to_s[-1,1].to_i == self.charge))
        charge = k.to_s[-1,1].to_i
        self.xcorr >= v
      elsif k_as_s == 'include_deltacnstar'
        if v == false
          self.deltacn <= 1.0
        else
          true
        end
      elsif k_as_s == 'ppm'
        self.send(k) <= v
      elsif k_as_s == 'deltacn'
        self.send(k) >= v
      else
        true
      end
    end
  end

  def fail_filters?(filter)
    !pass_filters?(filter)
  end

end

