require 'spec_helper'

require 'mspire/fasta'

describe 'basic fasta operations' do
  before do
    @headers = [">gi|5524211 [hello]", ">another B", ">again C"]
    @entries = ["LCLYTHIGRNIYYGSYLYSETWNTGIMLLLITMATAFMGYVLPWGQMSFWGATVITNLFSAIPYIGTNLV\nGLMPFLHTSKHRSMMLRPLSQALFWTLTMDLLTLTWIGSQPVEYPYTIIGQMASILYFSIILAFLPIAGX\nIENY", "ABCDEF\nGHIJK", "ABCD"]
    @sequences = @entries.map {|v| v.gsub("\n", '') }
    @data = {}
    @data['newlines'] = @headers.zip(@entries).map do |header, data|
      header + "\n" + data
    end.join("\n")
    @data['carriage_returns_and_newlines'] = @data['newlines'].gsub("\n", "\r\n")
    file_key_to_filename_pairs = @data.map do |k,v|
      file_key = k + '_file'
      filename = k + '.tmp'
      File.open(filename, 'w') {|out| out.print v }
      [file_key, filename]
    end
    file_key_to_filename_pairs.each {|k,v| @data[k] = v }
  end

  after do
    @data.select {|k,v| k =~ /_file$/ }.each do |k,filename|
      index = filename.sub('.tmp', '.index')
      [filename, index].each do |fn|
        File.unlink(fn) if File.exist? fn
      end
    end
  end

  def fasta_correct?(fasta)
    entries = fasta.map
    @headers.size.times.zip(entries) do |i,entry|
      header, sequence, entry = @headers[i], @sequences[i], entry
      entry.header.should_not == nil
      entry.sequence.should_not == nil
      entry.header.should == header[1..-1]
      entry.sequence.should == sequence
    end
  end

  xit 'can deliver length and description hashes' do
    # need to test
  end

  it 'can read a file' do
    %w(newlines_file carriage_returns_and_newlines_file).each do |file|
      Mspire::Fasta.open(@data[file]) do |fasta|
        fasta_correct? fasta
      end
    end
  end

  it 'can read an IO object' do
    %w(newlines_file carriage_returns_and_newlines_file).each do |file|
      File.open(@data[file]) do |io|
        fasta = Mspire::Fasta.new(io)
        fasta_correct? fasta
      end
    end
  end

  it 'can read a string' do
    %w(newlines carriage_returns_and_newlines).each do |key|
      fasta = Mspire::Fasta.new @data[key]
      fasta_correct? fasta
    end
  end

  it 'iterates entries with foreach' do
    %w(newlines_file carriage_returns_and_newlines_file).each do |file|
      Mspire::Fasta.foreach(@data[file]) do |entry|
        entry.should be_an_instance_of Bio::FastaFormat
      end
    end
  end

  it 'gives an iterator called with Mspire::Fasta.foreach and no block' do
    seqs = Mspire::Fasta.foreach(@data['newlines_file']).select {|e| e.header =~ /^gi/ }.map(&:sequence)
    seqs.size.should == 1
    seqs.first[0,4].should == 'LCLY'
  end

  it 'runs the documentation' do
    fasta_file = @data['newlines_file']
    ids = Mspire::Fasta.open(fasta_file) do |fasta| 
      fasta.map(&:entry_id)
    end
    ids.is_a?(Array)
    ids.should == %w(gi|5524211 another again)
   
    # this code is already tested above
    # File.open(fasta_file) do |io| 
    #   fasta = Mspire::Fasta.new(io)
    # end

    # taking a string
    string = ">id1 a simple header\nAAASDDEEEDDD\n>id2 header again\nPPPPPPWWWWWWTTTTYY\n"
    fasta = Mspire::Fasta.new(string)
    (simple, not_simple) = fasta.partition {|entry| entry.header =~ /simple/ }
    simple.first.header.include?("simple").should == true
    not_simple.first.header.include?("simple").should == false
  end
end
