
class Hash

  # any hashes within the hash will also be merged to the level specifid
  def merge_deep(hash2, level=1)
    if level == 1
      tmp_opts = {}
      self.each do |k,v|
        if (v.is_a?(Hash) and hash2[k].is_a?(Hash))
          tmp_opts[k] = v.merge(hash2[k])
        end
      end
      opts = self.merge(hash2)
      opts.merge!(tmp_opts)
      opts
    else
      raise NotImplementedError, "need to implement level > 1"
    end
  end
end

