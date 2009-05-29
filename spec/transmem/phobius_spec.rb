require 'yaml'

require File.expand_path( File.dirname(__FILE__) + '/../spec_helper' )

# contains shared behavior that we need.
require File.expand_path( File.dirname(__FILE__) + '/../transmem_spec_shared' )
require 'fasta'

require 'transmem/phobius'
index_klass = Phobius::Index
base_klass = Phobius

describe index_klass do
  before(:all) do
    @phobius_file = Tfiles + '/phobius.small.small.txt'
    @obj = Phobius::Index.new(@phobius_file)
    @test_hash = {
      'gi|16127995|ref|NP_414542.1| protein description' => 0, 
      'gi|16127996|ref|NP_414543.1| protein description' => 0, 
      'gi|16127997|ref|NP_414544.1| protein description' => 0, 
      'gi|16127998|ref|NP_414545.1| protein description' => 0, 
      'gi|16127999|ref|NP_414546.1| protein description' => 0, 
      'gi|16128000|ref|NP_414547.1| protein description' => 0, 
      'gi|16128001|ref|NP_414548.1| protein description' => 9, 
      'gi|16128002|ref|NP_414549.1| protein description' => 0, 
      'gi|16128003|ref|NP_414550.1| protein description' => 0, 
      'gi|16128004|ref|NP_414551.1| protein description' => 6, 
      'gi|16128005|ref|NP_414552.1| protein description' => 0, 
      'gi|90111078|ref|NP_414553.2| protein description' => 0, 
      'gi|16128007|ref|NP_414554.1| protein description' => 0, 
      'gi|16128008|ref|NP_414555.1| protein description' => 0, 
      'gi|16128009|ref|NP_414556.1| protein description' => 0, 
      'gi|16128010|ref|NP_414557.1| protein description' => 0, 
      'gi|16128011|ref|NP_414558.1| protein description' => 0, 
      'gi|16128012|ref|NP_414559.1| protein description' => 1, 
      'gi|49175991|ref|YP_025292.1| protein description' => 0, 
      'gi|16128013|ref|NP_414560.1| protein description' => 11, 
      'gi|16128014|ref|NP_414561.1| protein description' => 0, 
      'gi|16128015|ref|NP_414562.1| protein description' => 0, 
      'gi|16128016|ref|NP_414563.1| protein description' => 0, 
      'gi|16128017|ref|NP_414564.1| protein description' => 0, 
      'gi|16128018|ref|NP_414565.1| protein description' => 0, 
      'gi|16128019|ref|NP_414566.1| protein description' => 0, 
      'gi|16128020|ref|NP_414567.1| protein description' => 0, 
      'gi|16128021|ref|NP_414568.1| protein description' => 4, 
      'gi|16128022|ref|NP_414569.1| protein description' => 0, 
      'gi|16128023|ref|NP_414570.1| protein description' => 0, 
      'gi|16128024|ref|NP_414571.1| protein description' => 0, 
      'gi|16128025|ref|NP_414572.1| protein description' => 0, 
      'gi|16128026|ref|NP_414573.1| protein description' => 0, 
      'gi|16128027|ref|NP_414574.1| protein description' => 0, 
      'gi|90111079|ref|NP_414576.4| protein description' => 0, 
      'gi|90111080|ref|NP_414577.2| protein description' => 0, 
      'gi|16128030|ref|NP_414578.1| protein description' => 0, 
      'gi|49175993|ref|NP_414579.3| protein description' => 0, 
      'gi|16128032|ref|NP_414580.1| protein description' => 0, 
      'gi|16128033|ref|NP_414581.1| protein description' => 0, 
      'gi|16128034|ref|NP_414582.1| protein description' => 12,
      'gi|90111081|ref|NP_414583.2| protein description' => 0, 
      'gi|16128036|ref|NP_414584.1| protein description' => 0, 
      'gi|16128037|ref|NP_414585.1| protein description' => 0, 
      'gi|16128038|ref|NP_414586.1| protein description' => 0, 
      'gi|16128039|ref|NP_414587.1| protein description' => 12,
      'gi|16128040|ref|NP_414588.1| protein description' => 0, 
      'gi|16128041|ref|NP_414589.1| protein description' => 13,
      'gi|16128042|ref|NP_414590.1| protein description' => 0, 
      'gi|16128043|ref|NP_414591.1| protein description' => 0,
    }
    @ref_to_key = { 'gi|16127905|ref|NP_414542.1| thr operon leader peptide [Escherichia coli K12]' => 'gi|16127905|ref|NP_414542.1|',
      'SWN:PWP1_HUMAN PERIODIC TRYPTOPHAN PROTEIN 1 HOMOLOG' => 'SWN:PWP1_HUMAN',
      'MY:B|/-"[super]"duper!@#$%^&*(wil) and other stuff' => 'MY:B|/-[super]duper!@#$%^&*(wil)'}
  end
  it_should_behave_like 'a transmem index'
end

describe "a phobius parser", :shared => true do
  it 'parses a phobius file into a hash structure' do
    @file_to_hash.exist_as_a_file?.should be_true
    hash = @class.default_index(@file_to_hash)
    hash.should == @structure_to_create
  end
end

describe base_klass, "parsing the 'short' file format" do
  before(:all) do
    @class = base_klass
    @file_to_hash = Tfiles + '/phobius.small.small.txt'
    @structure_to_create = YAML.load(PhobiusSupportingFile::MY_YAML1)
  end
  it_should_behave_like 'a phobius parser'
end


describe index_klass, 'on small mock set' do
  before(:all) do
    phobius_file = Tfiles + '/phobius.small.small.txt'
    fasta_file = Tfiles + '/small.fasta'
    # Note that it needs a fasta object to do this!
    @obj = index_klass.new(phobius_file, Fasta.new(fasta_file))
    @tm_test = {
      :mykey => 'gi|16128001|ref|NP_414548.1|',

      # "MPDFFSFINSVLWGSVMIYLLFGAGCWFTFRTGFVQFRYIRQFGKSLKNSIHPQPGGLTSFQSLCTSLAARVGSGNLAGVALAITAGGPGAVFWMWVAAFIGMATSFAECSLAQLYKERDVNGQFRGGPAWYMARGLGMRWMGVLFAVFLLIAYGIIFSGVQANAVARALSFSFDFPPLVTGIILAVFTLLAITRGLHGVARLMQGFVPLMAIIWVLTSLVICVMNIGQLPHVIWSIFESAFGWQEAAGGAAGYTLSQAITNGFQRSMFSNEAGMGSTPNAAAAAASWPPHPAAQGIVQMIGIFIDTLVICTASAMLILLAGNGTTYMPLEGIQLIQKAMRVLMGSWGAEFVTLVVILFAFSSIVANYIYAENNLFFLRLNNPKAIWCLRICTFATVIGGTLLSLPLMWQLADIIMACMAITNLTAILLLSPVVHTIASDYLRQRKLGVRPVFDPLRYPDIGRQLSPDAWDDVSQE"
      # transmembrane sequences:
      # LWGSVMIYLLFGAGCWFTF
      # LAARVGSGNLAGVALAITAG
      # FWMWVAAFIGMATSFAECSLAQLY
      # LGMRWMGVLFAVFLLIAYGI
      # FPPLVTGIILAVFTLLAIT
      # GFVPLMAIIWVLTSLVICVMNIG
      # IVQMIGIFIDTLVICTASAMLILLA
      # VLMGSWGAEFVTLVVILFAFSSIVANYIY
      # IIMACMAITNLTAILLLSPVVHTIA
      :seqs => %w(VLWG LAIT LAG),
      :exps => 
      {
        :number => [3.0, 4.0, (2.0+3)/2],
        :fraction => [3.0/4, 4.0/4, ((2.0+3)/2)/3 ],
      }
    }
  end
  it_should_behave_like "a calculator of transmembrane overlap"
end


module PhobiusSupportingFile
  MY_YAML1 =<<END
--- 
gi|16128042|ref|NP_414590.1|: 
  :signal_peptide: true
  :num_certain_transmembrane_segments: 0
gi|16128017|ref|NP_414564.1|: 
  :signal_peptide: false
  :num_certain_transmembrane_segments: 0
gi|16128015|ref|NP_414562.1|: 
  :signal_peptide: false
  :num_certain_transmembrane_segments: 0
gi|16128038|ref|NP_414586.1|: 
  :signal_peptide: false
  :num_certain_transmembrane_segments: 0
gi|90111081|ref|NP_414583.2|: 
  :signal_peptide: false
  :num_certain_transmembrane_segments: 0
gi|16128022|ref|NP_414569.1|: 
  :signal_peptide: false
  :num_certain_transmembrane_segments: 0
gi|16128020|ref|NP_414567.1|: 
  :signal_peptide: false
  :num_certain_transmembrane_segments: 0
gi|16128009|ref|NP_414556.1|: 
  :signal_peptide: false
  :num_certain_transmembrane_segments: 0
gi|16128000|ref|NP_414547.1|: 
  :signal_peptide: false
  :num_certain_transmembrane_segments: 0
gi|16128043|ref|NP_414591.1|: 
  :signal_peptide: false
  :num_certain_transmembrane_segments: 0
gi|16128032|ref|NP_414580.1|: 
  :signal_peptide: false
  :num_certain_transmembrane_segments: 0
gi|16128030|ref|NP_414578.1|: 
  :signal_peptide: false
  :num_certain_transmembrane_segments: 0
gi|16128014|ref|NP_414561.1|: 
  :signal_peptide: false
  :num_certain_transmembrane_segments: 0
gi|16128005|ref|NP_414552.1|: 
  :signal_peptide: false
  :num_certain_transmembrane_segments: 0
gi|16128003|ref|NP_414550.1|: 
  :signal_peptide: false
  :num_certain_transmembrane_segments: 0
gi|16127999|ref|NP_414546.1|: 
  :signal_peptide: true
  :num_certain_transmembrane_segments: 0
gi|16128037|ref|NP_414585.1|: 
  :signal_peptide: true
  :num_certain_transmembrane_segments: 0
gi|16128021|ref|NP_414568.1|: 
  :transmembrane_segments: 
  - :start: 12
    :stop: 31
  - :start: 70
    :stop: 88
  - :start: 100
    :stop: 117
  - :start: 137
    :stop: 157
  :signal_peptide: false
  :num_certain_transmembrane_segments: 4
gi|16128008|ref|NP_414555.1|: 
  :signal_peptide: false
  :num_certain_transmembrane_segments: 0
gi|90111080|ref|NP_414577.2|: 
  :signal_peptide: false
  :num_certain_transmembrane_segments: 0
gi|90111079|ref|NP_414576.4|: 
  :signal_peptide: false
  :num_certain_transmembrane_segments: 0
gi|16128026|ref|NP_414573.1|: 
  :signal_peptide: false
  :num_certain_transmembrane_segments: 0
gi|16128004|ref|NP_414551.1|: 
  :transmembrane_segments: 
  - :start: 12
    :stop: 31
  - :start: 37
    :stop: 56
  - :start: 63
    :stop: 84
  - :start: 96
    :stop: 116
  - :start: 123
    :stop: 143
  - :start: 149
    :stop: 169
  :signal_peptide: false
  :num_certain_transmembrane_segments: 6
gi|16128036|ref|NP_414584.1|: 
  :signal_peptide: false
  :num_certain_transmembrane_segments: 0
gi|16128034|ref|NP_414582.1|: 
  :transmembrane_segments: 
  - :start: 12
    :stop: 30
  - :start: 50
    :stop: 71
  - :start: 91
    :stop: 116
  - :start: 145
    :stop: 163
  - :start: 195
    :stop: 216
  - :start: 228
    :stop: 251
  - :start: 263
    :stop: 286
  - :start: 318
    :stop: 335
  - :start: 347
    :stop: 366
  - :start: 406
    :stop: 425
  - :start: 446
    :stop: 466
  - :start: 472
    :stop: 495
  :signal_peptide: false
  :num_certain_transmembrane_segments: 12
gi|16128007|ref|NP_414554.1|: 
  :signal_peptide: true
  :num_certain_transmembrane_segments: 0
gi|16127998|ref|NP_414545.1|: 
  :signal_peptide: false
  :num_certain_transmembrane_segments: 0
gi|16127996|ref|NP_414543.1|: 
  :signal_peptide: false
  :num_certain_transmembrane_segments: 0
gi|16128041|ref|NP_414589.1|: 
  :transmembrane_segments: 
  - :start: 6
    :stop: 24
  - :start: 31
    :stop: 49
  - :start: 55
    :stop: 72
  - :start: 84
    :stop: 111
  - :start: 117
    :stop: 135
  - :start: 147
    :stop: 169
  - :start: 181
    :stop: 202
  - :start: 214
    :stop: 233
  - :start: 239
    :stop: 258
  - :start: 270
    :stop: 290
  - :start: 296
    :stop: 315
  - :start: 327
    :stop: 348
  - :start: 360
    :stop: 378
  :signal_peptide: false
  :num_certain_transmembrane_segments: 13
gi|16128039|ref|NP_414587.1|: 
  :transmembrane_segments: 
  - :start: 20
    :stop: 42
  - :start: 54
    :stop: 74
  - :start: 86
    :stop: 104
  - :start: 110
    :stop: 132
  - :start: 144
    :stop: 166
  - :start: 172
    :stop: 193
  - :start: 242
    :stop: 263
  - :start: 283
    :stop: 303
  - :start: 310
    :stop: 329
  - :start: 335
    :stop: 358
  - :start: 370
    :stop: 390
  - :start: 402
    :stop: 421
  :signal_peptide: false
  :num_certain_transmembrane_segments: 12
gi|49175993|ref|NP_414579.3|: 
  :signal_peptide: false
  :num_certain_transmembrane_segments: 0
gi|16128025|ref|NP_414572.1|: 
  :signal_peptide: false
  :num_certain_transmembrane_segments: 0
gi|16128023|ref|NP_414570.1|: 
  :signal_peptide: false
  :num_certain_transmembrane_segments: 0
gi|16128012|ref|NP_414559.1|: 
  :transmembrane_segments: 
  - :start: 25
    :stop: 44
  :signal_peptide: false
  :num_certain_transmembrane_segments: 1
gi|16128033|ref|NP_414581.1|: 
  :signal_peptide: false
  :num_certain_transmembrane_segments: 0
gi|16128019|ref|NP_414566.1|: 
  :signal_peptide: false
  :num_certain_transmembrane_segments: 0
gi|49175991|ref|YP_025292.1|: 
  :signal_peptide: true
  :num_certain_transmembrane_segments: 0
gi|16127997|ref|NP_414544.1|: 
  :signal_peptide: false
  :num_certain_transmembrane_segments: 0
gi|16127995|ref|NP_414542.1|: 
  :signal_peptide: false
  :num_certain_transmembrane_segments: 0
gi|16128040|ref|NP_414588.1|: 
  :signal_peptide: false
  :num_certain_transmembrane_segments: 0
gi|16128024|ref|NP_414571.1|: 
  :signal_peptide: false
  :num_certain_transmembrane_segments: 0
gi|16128013|ref|NP_414560.1|: 
  :transmembrane_segments: 
  - :start: 12
    :stop: 39
  - :start: 59
    :stop: 79
  - :start: 91
    :stop: 114
  - :start: 126
    :stop: 145
  - :start: 154
    :stop: 175
  - :start: 181
    :stop: 200
  - :start: 207
    :stop: 238
  - :start: 258
    :stop: 276
  - :start: 288
    :stop: 312
  - :start: 324
    :stop: 351
  - :start: 363
    :stop: 380
  :signal_peptide: false
  :num_certain_transmembrane_segments: 11
gi|16128011|ref|NP_414558.1|: 
  :signal_peptide: false
  :num_certain_transmembrane_segments: 0
gi|90111078|ref|NP_414553.2|: 
  :signal_peptide: false
  :num_certain_transmembrane_segments: 0
gi|16128002|ref|NP_414549.1|: 
  :signal_peptide: false
  :num_certain_transmembrane_segments: 0
gi|16128027|ref|NP_414574.1|: 
  :signal_peptide: true
  :num_certain_transmembrane_segments: 0
gi|16128018|ref|NP_414565.1|: 
  :signal_peptide: false
  :num_certain_transmembrane_segments: 0
gi|16128016|ref|NP_414563.1|: 
  :signal_peptide: false
  :num_certain_transmembrane_segments: 0
gi|16128010|ref|NP_414557.1|: 
  :signal_peptide: false
  :num_certain_transmembrane_segments: 0
gi|16128001|ref|NP_414548.1|: 
  :transmembrane_segments: 
  - :start: 12
    :stop: 30
  - :start: 68
    :stop: 87
  - :start: 93
    :stop: 116
  - :start: 137
    :stop: 156
  - :start: 176
    :stop: 194
  - :start: 206
    :stop: 228
  - :start: 297
    :stop: 321
  - :start: 342
    :stop: 370
  - :start: 414
    :stop: 438
  :signal_peptide: false
  :num_certain_transmembrane_segments: 9
END

end
