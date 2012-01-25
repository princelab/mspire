
class IO
  # saves the position and returns to it after the block
  # is executed. Returns the block's reply.  if rewind, io.rewind is called
  # before handing the io object to the block.
  def bookmark(rewind=false, &block)
    start = self.pos
    self.rewind if rewind
    reply = block.call(self) 
    self.pos = start
    reply
  end
end
