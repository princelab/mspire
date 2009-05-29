require File.expand_path( File.dirname(__FILE__) + '/spec_helper' )

require 'spec_id_xml'

describe SpecIDXML, 'included with a simple object' do
  before(:all) do
    class Bob
      include SpecIDXML
      def initialize(first=nil, second=nil)
        @first = first ; @second = second 
      end
    end
  end

  it 'creates short element xmls using an objects instance variables' do
    obj = Bob.new(1, 2) 
    st = obj.short_element_xml_from_instance_vars("bob")
    # the ordering is arbitrary: "<bob first=\"1\" second=\"2\"/>\n"
    st.should =~ /second="2"/
    st.should =~ /first="1"/
    st.should =~ /^<bob /
    st.should =~ />$/
  end

  it 'escapes special characters' do
    obj = Bob.new
    obj.escape_special_chars("&><\"'").should == "&amp;&gt;&lt;&quot;&apos;"
    obj.escape_special_chars("PE&PT>I<D\"E'").should == "PE&amp;PT&gt;I&lt;D&quot;E&apos;"
  end

end
  

