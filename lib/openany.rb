
# takes a filename or an io object, hands a rewinded io object to the
# reciever and then closes the file or places the io in the original
# position.
def openany(arg, &block)
  io = 
    if arg.is_a?(String)  # filename
      File.open(arg)
    else
      orig_pos = arg.pos
      arg.rewind
      arg
    end
  reply = block.call(io)
  if arg.is_a?(String)  # filename
    io.close
  else
    arg.pos = orig_pos
  end
  reply
end


