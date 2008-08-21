
module XML
  HourMinuteMatch = /[MH]/o 
  # returns a float object of seconds
  # doesn't support year month, etc, yet
  def self.duration_to_seconds(string)
    case x = string[0,2]
    when 'PT'
      rest = string[2..-1]
      # usually it will be this 'PT1.223434S':
      if rest !~ HourMinuteMatch
        rest[0...-1].to_f
      else
        addit = ''
        total_secs = 0
        total_secs_as_float = nil
        rest.split('').each do |let|
          case let
          when 'H'
            total_secs += addit.to_i * 3600
            addit = ''
          when 'M'
            total_secs += addit.to_i * 60
            addit = ''
          when 'S'
            total_secs_as_float = total_secs.to_f
            total_secs_as_float += addit.to_f
          else
            addit << let
          end
        end
        total_secs_as_float
      end
    else 
      abort 'need to include support for other durations'
    end
  end
end
