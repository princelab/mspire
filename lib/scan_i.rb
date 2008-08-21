
# http://groups.google.com/group/comp.lang.ruby/browse_thread/thread/7370f94e852c0fae/4068c8c1c1c158ee
class String
  def scan_i seq
    pos=0
    ndx=[]
    slen = seq.length
    while i=index(seq,pos)
      ndx << i
      pos = i + slen
    end
    ndx
  end

  #def scan_enum seq
  #  self.enum_for(:scan, seq).map do 
  #    $~.offset(0)[0]
  #  end
  #end
end

