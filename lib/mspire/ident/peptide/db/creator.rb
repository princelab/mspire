require 'optparse'
require 'mspire/digester'
require 'mspire/fasta'
require 'mspire/ident/peptide/db'

class Mspire::Ident::Peptide::Db::Creator
  MAX_NUM_AA_EXPANSION = 3

  # the twenty standard amino acids
  STANDARD_AA = %w(A C D E F G H I K L M N P Q R S T V W Y)
  EXPAND_AA = {'X' => STANDARD_AA}

  DEFAULT_PEPTIDE_CENTRIC_DB = {
    missed_cleavages: 2, 
    min_length: 4,
    enzyme: Mspire::Digester[:trypsin], 
    remove_digestion_file: true, 
    cleave_initiator_methionine: true, 
    expand_aa: true, 
    uniprot: true 
  }

  def self.cmdline(argv)

    opt = {
      :remove_digestion_file => true,
      :enzyme => Mspire::Digester[:trypsin]
    }
    opts = OptionParser.new do |op|
      op.banner = "usage: #{File.basename($0)} <file>.fasta ..."
      op.separator "output: "
      op.separator "    <file>.msd_clvg<missed_cleavages>.min_aaseq<min_length>.yml"
      op.separator "format:"
      op.separator "    PEPTIDE: ID1<tab>ID2<tab>ID3..."
      op.separator ""    
      op.separator "    Initiator Methionines - by default, will generate two peptides"
      op.separator "    for any peptide found at the N-termini starting with 'M'"
      op.separator "    (i.e., one with and one without the leading methionine)"
      op.separator ""
      op.on("--missed-cleavages <#{opt[:missed_cleavages]}>", Integer, "max num of missed cleavages") {|v| opt[:missed_cleavages] = v }
      op.on("--min-length <#{opt[:min_length]}>", Integer, "the minimum peptide aaseq length") {|v| opt[:min_length] = v }
      op.on("--no-cleaved-methionine", "does not cleave off initiator methionine") { opt[:cleave_initiator_methionine] = false }
      op.on("--no-expand-x", "don't enumerate aa possibilities", "(removes these peptides)") { opt[:expand_aa] = false }
      op.on("--no-uniprot", "use entire protid section of fasta header", "for non-uniprot fasta files") { opt[:uniprot] = false }
      #op.on("--trie", "use a trie (for very large uniprot files)", "must have fast_trie gem installed") {|v| opt[:trie] = v }

      op.on("-e", "--enzyme <name>", "enzyme for digestion") {|v| opt[:enzyme] = Mspire::Insilico::Digester.const_get(v.upcase) }
      op.on("-v", "--verbose", "talk about it") { $VERBOSE = 5 }
      op.on("--list-enzymes", "lists approved enzymes and exits") do
      op.on("-v", "--verbose", "talk about it") { $VERBOSE = 5 }
        puts Mspire::Digester::ENZYMES.keys.join("\n")
        exit
      end
    end

    opts.parse!(argv)

    if argv.size == 0
      puts opts || exit
    end

    argv.map do |file|
      creator = Mspire::Ident::Peptide::Db::Creator.new
      creator.create(file, opt)
    end
  end

  # returns the name of the digestion file that was written
  def create_digestion_file(fasta_file, opts={})
    opts = DEFAULT_PEPTIDE_CENTRIC_DB.merge(opts)

    (missed_cleavages, enzyme, cleave_initiator_methionine, expand_aa) = opts.values_at(:missed_cleavages, :enzyme, :cleave_initiator_methionine, :expand_aa) 
    start_time = Time.now
    print "Digesting #{fasta_file} ..." if $VERBOSE

    letters_to_expand_re = Regexp.new("[" << Regexp.escape(EXPAND_AA.keys.join) << "]")

    base = fasta_file.chomp(File.extname(fasta_file))
    digestion_file = base + ".msd_clvg#{missed_cleavages}.peptides"
    File.open(digestion_file, "w") do |fh|
      Mspire::Fasta.open(fasta_file) do |fasta|
        fasta.each do |prot|
          peptides = enzyme.digest(prot.sequence, missed_cleavages)
          if (cleave_initiator_methionine && (prot.sequence[0,1] == "M"))
            m_peps = []
            init_methionine_peps = []
            peptides.each do |pep|
              # if the peptide is at the beginning of the protein sequence
              if prot.sequence[0,pep.size] == pep
                m_peps << pep[1..-1]
              end
            end
            peptides.push(*m_peps)
          end
          peptides = 
            if expand_aa
              peptides.flat_map do |pep|
                (pep =~ letters_to_expand_re) ? expand_peptides(pep, EXPAND_AA) : pep
              end
            else
              peptides.select {|pep| pep !~ letters_to_expand_re }
            end
          header = prot.header
          id = opts[:uniprot] ? Mspire::Fasta.uniprot_id(header) : header.split(/\s+/).first
          fh.puts( id + "\t" + peptides.join(" ") )
        end
      end
    end
    puts "#{Time.now - start_time} sec" if $VERBOSE
    digestion_file
  end

  # returns the full path of the created file
  def db_from_fasta_digestion_file(digestion_file, opts={})
    opts = DEFAULT_PEPTIDE_CENTRIC_DB.merge(opts)

    start_time = Time.now
    puts "Organizing raw digestion #{digestion_file} ..." if $VERBOSE

    puts "#{Time.now - start_time} sec" if $VERBOSE
    hash_like = hash_like_from_digestion_file(digestion_file, opts[:min_length], opts[:trie])

    base = digestion_file.chomp(File.extname(digestion_file))
    final_outfile = base + ".min_aaseq#{opts[:min_length]}" + ".yml"

    start_time = Time.now
    print "Writing #{hash_like.size} peptides to #{} ..." if $VERBOSE

    File.open(final_outfile, 'w') do |out|
      hash_like.each do |k,v|
        out.puts( [k, v.join(Mspire::Ident::Peptide::Db::PROTEIN_DELIMITER)].join(Mspire::Ident::Peptide::Db::KEY_VALUE_DELIMITER) )
        #out.puts "#{k}#{Mspire::Ident::Peptide::Db::KEY_VALUE_DELIMITER}#{v}"       
      end
    end
    puts "#{Time.now - start_time} sec" if $VERBOSE

    if opts[:remove_digestion_file]
      File.unlink(digestion_file)
    end
    File.expand_path(final_outfile)
  end

  def hash_like_tree
    require 'trie'
    trie = Trie.new
    def trie.[](key)
      val = self.get(key) 
      if val.nil?
        self.add(key,"")
        self.get(key)
      else
        val
      end
    end
    trie
  end

  def hash_like_from_digestion_file(digestion_file, min_length, use_trie=false)
    if use_trie
      raise NotImplementedError
      #puts "using trie" if $VERBOSE
      #trie = hash_like_tree
      #line_cnt = 0
      #::IO.foreach(digestion_file) do |line|
        #line_cnt += 1
        ##puts "LINE COUND"
        ##p line_cnt
        #(prot, *peps) = line.chomp!.split(/\s+/)
        ##p peps
        ##p peps.class
        ## prot is something like this: "P31946"
        #puts line
        #peps.each do |pep|
          #if pep.size >= min_length
            #to_set = 
              #if val = trie.get(pep)
                #val +  Mspire::Ident::Peptide::Db::PROTEIN_DELIMITER + prot
              #else
                #prot
              #end
            #p to_set.size
            #trie.add(pep, to_set)
          #end
        #end
        #cnt += 1
        #puts cnt if (cnt % 1000) == 0
      #end
      #abort "HERE"
      #trie
    else
      hash = Hash.new {|h,k| h[k] = [] }
      ::IO.foreach(digestion_file) do |line|
        line.chomp!
        (prot, *peps) = line.split(/\s+/)
        # prot is something like this: "P31946"
        peps.uniq!
        peps.each do |pep|
          if pep.size >= min_length
            hash[pep] << prot
          end
        end
      end
      hash
    end
  end

  # writes a new file with the added 'min_aaseq<Integer>'
  # creates a temporary digestion file that contains all peptides digesting
  # with certain missed_cleavages (i.e., min_seq_length is not applied to
  # this file but on the final peptide centric db)
  # returns the full name of the written file.
  def create(fasta_file, opts={})
    opts = DEFAULT_PEPTIDE_CENTRIC_DB.merge(opts)
    digestion_file = create_digestion_file(fasta_file, opts)
    puts "created file of size: #{File.size(digestion_file)}" if $VERBOSE
    db_from_fasta_digestion_file(digestion_file, opts)
  end

  # does combinatorial expansion of all letters requesting it.
  # expand_aa is hash like: {'X'=>STANDARD_AA}
  # returns nil if there are more than MAX_NUM_AA_EXPANSION amino acids to
  # be expanded
  # returns an empty array if there is no expansion
  def expand_peptides(peptide, expand_aa_hash)
    letters_in_order = expand_aa_hash.keys.sort
    index_and_key = []
    peptide.split('').each_with_index do |char,i| 
      if let_index = letters_in_order.index(char) 
        index_and_key << [i, letters_in_order[let_index]]
      end
    end
    if index_and_key.size > MAX_NUM_AA_EXPANSION
      return nil
    end
    to_expand = [peptide]
    index_and_key.each do |i,letter|
      new_peps = []
      while current_pep = to_expand.shift do
        new_peps << expand_aa_hash[letter].map {|v| dp = current_pep.dup ; dp[i] = v ; dp }
      end
      to_expand = new_peps.flatten
    end
    to_expand
  end
end

