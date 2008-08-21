
module SpecID ; end
module SpecID::Precision ; end

class SpecID::Precision::Filter
  class Interactive
    attr_accessor :file
    attr_accessor :verbose

    # the file contains the interactive commands
    def initialize(file=nil, verbose=false)
      @verbose = verbose
      if file
        @file = file
        @lines = IO.readlines(file)
      else
        @lines = nil
      end
    end

    def passing(opts, answer)
      puts "****************************************************" if @verbose
    end
    # takes opts and modifies the keys in question, or returns nil
    # shortcut map takes each proper key and designates a shortcut (if any)

    def filter_args(opts_to_change, changing_keys, shortcut_map, casting_map)
      shortcut_order = changing_keys.map {|k| shortcut_map[k] }
      casting_array = changing_keys.map {|k| casting_map[k] }
      return_val = true
      reply = nil
      base_args = opts_to_change.values_at( *changing_keys )
      #b = base_args
      current_values = changing_keys.map {|v| "#{shortcut_map[v]}:#{opts_to_change[v]}" }
      out(current_values.join(" ")) if @verbose
      #out "#{b[0]} #{b[1]} #{b[2]} dcn:#{b[3]} ppm:#{b[4]}"
      loop do
        reply = 
          if @lines
            if @lines.size > 0
              @lines.shift.chomp
            else
              'q'
            end
          else
            gets.chomp
          end
        answer = prep_reply(reply, base_args, shortcut_order, casting_array)
        if answer == false
          out(interactive_help(changing_keys, shortcut_map)) if @verbose
        elsif answer == nil
          return nil
        else
          answer.zip(changing_keys) do |newval,changing_key|
            opts_to_change[changing_key] = newval
          end
          return_val = true
          break
        end
      end
      return_val
    end

    def out(string)
      puts string
    end

    def interactive_help(changing_keys, shortcut_map)
      shortcuts = changing_keys.map {|v| shortcut_map[v] }
      as_array = shortcuts.map {|v| "<#{v}>" }
      as_hash = shortcuts.map {|v| "#{v}:<#{v}>" }
      string = []
      string << "******************************************************************************"
      string << "INTERACTIVE FILTERING HELP:"
      string << "enter as an array of values    : #{as_array.join(' ')}"
      string << "or as keys and values          : #{as_hash.join(' ')}"
      string << "or some of the keys and values : #{as_hash.last}"
      if changing_keys.size >= 3
        string << "or mix array and keys/values   : #{as_array[0]} #{as_array[1]} #{as_hash.last}"
      end
      string << "etc..."
      string << "<enter> to (re)run current values"
      string << "'q' to quit"
      string << "******************************************************************************"
      string.join("\n")
    end

    # assumes its already chomped
    # updates the 5 globals
    # returns nil if 'q'
    def prep_reply(reply, base, shortcut_order, casting_array)
      if reply == 'q' 
        return nil
      end
      if reply =~ /^\s*$/
        base
      elsif reply
        arr = reply.split(/\s+/)
        to_change_ar = []
        to_change_hash = {}
        arr.each do |it|
          if it.include? ':'
            (k,v) = it.split(':')
            to_change_hash[k] = v
          else
            to_change_ar << it
          end
        end
        to_change_ar.each_with_index do |tc,i|
            base[i] = tc
        end
        to_change_hash.each do |k,v|
          index = shortcut_order.index(k)
          if index.nil?
            out("BAD ARG: #{k}:#{v}") if @verbose
          end
          base[index] = v
        end
        base.zip(casting_array).map do |v,cast_proc| 
          begin
            cast_proc.call(v) 
          rescue NoMethodError
            out "BAD ARG: #{tc}" if @verbose
            return false
          end
        end
      else
        false
      end
    end

  end
end

