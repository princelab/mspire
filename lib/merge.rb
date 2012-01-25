module Merge
  # allows object attributes to be set from a hash
  def merge!(hash={}, &block)
    hash.each {|k,v| send("#{k}=",v) }
    block.call(block_arg) if block
  end
end
