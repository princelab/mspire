
# if given a filename, writes to the file (and returns the filename),
# otherwise, writes to a string. Yields an io object to write to.
def write_file_or_string(filename=nil, &block)
  out = 
    if filename
      File.open(filename,'w')
    else
      StringIO.new
    end
  block.call(out)
  if filename
    out.close
    filename
  else
    out.string
  end
end
