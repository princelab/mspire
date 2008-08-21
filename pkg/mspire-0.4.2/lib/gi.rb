require 'open-uri'
require 'rexml/document'
require 'rexml/streamlistener'

$ANNOTS = []

class GIListener
  include REXML
  include StreamListener

  attr_accessor :annotations

  def initialize
    @get_title = false
    @annotations = []
  end

  def tag_start(name, attributes)
    #puts "NAME" + name
    #p attributes
    if name == "Item" && attributes["Name"] == "Title"
      @get_title = true 
    end
  end

  def text(text)
    #puts "TEXT: " + text + @get_title.to_s
    if @get_title
      #puts "GETTING TITLE!"
      @annotations.push text.chomp
      @get_title = false
    end
  end

end



class GI
  BATCH_SIZE = 500
  # takes an array of gi numbers and returns an array of annotation
  # This allows use of the batch search mode on NCBI
  # returns nil if no internet connection
  def self.gi2annot(list_of_gi_numbers) 
    annots = []
    loop do
      batch = list_of_gi_numbers.slice!(0..BATCH_SIZE)
      if batch.size == 0 then break end
      string = batch.join(",")
      url = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi?db=protein&retmode=xml&id=#{string}"
      #puts url
      begin
        open(url) do |handle|
          if handle.is_a? StringIO 
            io_input = handle
          else
            io_input = handle.read
          end
          annots.push( *(parse_etool_output(io_input)) )
        end
      rescue SocketError
        return nil
      end
    end
    annots
  end

  protected
  # Returns a list of Annotation strings
  def self.parse_etool_output(handle)
    listener = GIListener.new
    parser = REXML::Parsers::StreamParser.new(handle, listener)
    parser.parse 
    listener.annotations
  end


end



=begin

<?xml version="1.0" encoding="ISO-8859-1"?>
<!DOCTYPE eSummaryResult PUBLIC "-//NLM//DTD eSummaryResult, 11 May 2002//EN" "http://www.ncbi.nlm.nih.gov/entrez/query/DTD/eSummary_041029.dtd">
<eSummaryResult>

<DocSum>
<Id>24115498</Id>
<Item Name="Caption" Type="String">NP_710008</Item>
<Item Name="Title" Type="String">chaperonin GroEL [Shigella flexneri 2a str. 301]</Item>
<Item Name="Extra" Type="String">gi|24115498|ref|NP_710008.1|[24115498]</Item>
<Item Name="Gi" Type="Integer">24115498</Item>
<Item Name="CreateDate" Type="String">2002/10/16</Item>

<Item Name="UpdateDate" Type="String">2006/04/03</Item>
<Item Name="Flags" Type="Integer">512</Item>
<Item Name="TaxId" Type="Integer">198214</Item>
<Item Name="Status" Type="String">live</Item>
<Item Name="ReplacedBy" Type="String"></Item>
<Item Name="Comment" Type="String"><![CDATA[  ]]></Item>
</DocSum>


<DocSum>
<Id>434011</Id>
<Item Name="Caption" Type="String">CAA24741</Item>

<Item Name="Title" Type="String">unnamed protein product [Escherichia coli]</Item>
<Item Name="Extra" Type="String">gi|434011|emb|CAA24741.1|[434011]</Item>
<Item Name="Gi" Type="Integer">434011</Item>
<Item Name="CreateDate" Type="String">1983/12/06</Item>
<Item Name="UpdateDate" Type="String">2005/04/18</Item>
<Item Name="Flags" Type="Integer">0</Item>
<Item Name="TaxId" Type="Integer">562</Item>
<Item Name="Status" Type="String">live</Item>
<Item Name="ReplacedBy" Type="String"></Item>

<Item Name="Comment" Type="String"><![CDATA[  ]]></Item>
</DocSum>

</eSummaryResult>

=end
