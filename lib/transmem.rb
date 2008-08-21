
# A transmemIndex is a hash that takes a fasta reference as key and returns
# a structured hash containing the transmembrane information.
module TransmemIndex
  
  # returns :toppred or :phobius
  def self.filetype(file)
    tp = nil
    File.open(file) do |fh|
      while (line = fh.gets)
        case line
        when /SEQENCE/
          tp = :phobius 
          break
        when /    0  0 i/
          tp = :phobius  # if they don't have the headers, 
                         # this will pick it up if they have a 
                         # single prot without tm or signal peptide.
          break
        when /Algorithm specific parameters/
          tp = :toppred  # New text
          break
        when /<parameters>/
          tp = :toppred  # XML
          break
        end
      end
    end
    tp
  end

  def reference_to_key(reference)
    # needs to be subclassed or written
  end
  
  # right now accepts toppred.out files
  # Phobius objects can use the fasta object to update their hash for methods
  # like avg_overlap
  def self.new(file, fasta=nil)
    case x = filetype(file)
    when :toppred
      require 'transmem/toppred'
      TopPred::Index.new(file)
    when :phobius
      require 'transmem/phobius'
      # warn "WARNING: You have NO fasta object with Phobius based TransmemIndex! (which needs one to do proper indexing!)" unless fasta
      Phobius::Index.new(file, fasta)
    else 
      raise ArgumentError, "#{x} filetype for #{file} not recognized!"
    end
  end

  # returns a hash of key -> num certain transmembrane segments
  def num_certain_index
    hash = {}
    self.each do |k,v|
      hash[k] = v[:num_certain_transmembrane_segments] || 0
    end
    hash
  end

  # tp = :number or :fraction which is the fraction of the sequence size
  # returns the average number of overlapping amino acids with transmembrane
  # segments
  # returns nil if there is no protein by that key
  def avg_overlap(key, sequence, tp=:number)
    if self.key? key
      numbers = num_transmem_aa(self[key], sequence)
      if numbers.size > 0
        sum = 0
        numbers.each {|num| sum += num}
        avg_num = sum.to_f / numbers.size
        # the one line way to do it
        #avg_num = numbers.inject(0) {|memo,num| num + memo }.to_f / numbers.size
        if tp == :fraction
          avg_num / sequence.size
          # this is the same as doing this:
          #numbers.inject(0.0) {|memo,num| (num.to_f/seq_size + memo) } / numbers.size
        else
          avg_num
        end
      else
        0.0
      end
    else  # what to do if the protein isn't there?? which happens on occasion
      nil
    end
  end

  # returns an array (usually length of 1) of the number of amino acids
  # contained inside transmembrane spanning segments.
  # assumes that tmhash has the key 'transmembrane_segments'
  # if there are no transmembrane segments, returns empty array.
  def num_transmem_aa(tmhash, sequence)
    if tmhash.key? :transmembrane_segments
      ranges = tmhash[:transmembrane_segments].map do |tmseg|
        Range.new( tmseg[:start]-1, tmseg[:stop]-1 )
      end
      num_overlapping_chars(tmhash[:aaseq], ranges, sequence)
    else
      []
    end
  end

  # returns an array of the number of overlapping sequences in substring with
  # the substrings defined in start_stop_doublets within full_sequence
  # start_stop_doublets should be 0 indexed!!!
  # the span includes the 'stop' position i.e., full_sequence[start..stop]
  def num_overlapping_chars(full_sequence, ranges, substring)
    #start_positions = aaseq.enum_for(:scan, substring).map { $~.offset(0)[0]}
    if ranges.size == 0
      []
      #full_sequence.enum_for(:scan, substring).map { 0 }
    else
      substring_ranges = []
      pos = 0
      slen = substring.size
      while i=full_sequence.index(substring,pos)
        substring_ranges << Range.new(i, i+slen-1)
        pos = i + slen
      end
      # brute force way
      last_tm_range = ranges.last.last
      to_return = substring_ranges.map do |sb|
        overlap = 0
        # there's got to be a much simpler way to do this, but this does work...
        ranges.each do |tm|
          (frst, lst) = 
            if tm.include?( sb.first )
              [tm, sb]
            elsif tm.include?( sb.last )
              [sb, tm]
            else
              nil
            end
          if frst
            if lst.last <= frst.last
              overlap += (frst.last+1 - frst.first) - (lst.first - frst.first) - (frst.last - lst.last)
            else 
              overlap += (frst.last+1 - frst.first) - (lst.first - frst.first)
            end
          end
        end
        overlap
      end
    end
  end


end


#substring_ranges = full_sequence.enum_for(:scan, substring).map do 
#        (ofirst, olast) = $~.offset(0) 
#        Range.new(ofirst, olast - 1)
#      end

