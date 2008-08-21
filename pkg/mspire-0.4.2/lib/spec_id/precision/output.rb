

module SpecID ; end
module SpecID::Precision ; end

module SpecID::Precision::Output

  # takes a format type (as symbol) and the handle to write to
  # if handle_or_file is a file, will open it and close (on calling close)
  # if it is a handle, will not close it
  def initialize(format, handle_or_file)
    @handle = 
      if handle_or_file.is_a? String
        @need_to_close = true
        File.open(handle_or_file, 'w')
      else
        @need_to_close = false
        handle_or_file
      end
    @format = format
  end

  # returns self
  def print(answer)
    send( @format, @handle, answer )
    self
  end

  # turns all keys that are symbols into strings (recursively into *Hashes*)
  def self.symbol_keys_to_string(hash)
    new_hash = {}
    hash.each do |k,v|
      new_value = 
        if v.is_a? Hash
          symbol_keys_to_string(v)
        else
          v
        end
      if k.is_a? Symbol
        new_hash[k.to_s] = new_value
      else
        new_hash[k] = new_value
      end
    end
    new_hash
  end

    # TODO: implement recursively, this has just grown and grown terribly
  def hash_as_string(hash)
    hash.inspect
  end

   # will close the handle if it is a File object
  def close
    if @need_to_close
      @handle.close 
    end
  end

end
