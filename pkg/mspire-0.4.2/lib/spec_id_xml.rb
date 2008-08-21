
# I would prefer to call this SpecID::XML, but I keep getting an error:
# /home/john/Proteomics/msprot/lib/spec_id/bioworks.rb:412: warning: toplevel
# constant XML referenced by SpecID::XML' This works around that for now.
# Any major xml elements should return a newline at the end for simple
# concatenation into a file
module SpecIDXML

  MSial_chrs_hash = {
    '"' => '&quot;',
    '&' => '&amp;',
    "'" => '&apos;',
    '<' => '&lt;',
    '>' => '&gt;',
  }

  # substitutes special xml chars
  def escape_special_chars(string)
    string.split('').map do |char|
      if MSial_chrs_hash.key? char ; MSial_chrs_hash[char] 
        # if x = MSial_chrs_hash[char] ; x  # <-- that's slightly slower
      else ; char end
    end.join
  end

  $DEPTH = 0

  def tabs
    # this is ugly
    string = ""
    $DEPTH.times { string << "\t" }
    string
  end


  def param_xml(obj, symbol)
    tabs + '<parameter name="' + "#{symbol}" + '" value="' + "#{obj.send(symbol)}" + '"/>'
  end

  def params_xml(obj, *symbol_list)
    symbol_list.collect { |sy|
      param_xml(obj, sy)
    }.join("\n") + "\n"
  end

  def short_element_xml(element, att_list)
    "#{tabs}<#{element} #{attrs_xml(att_list)}/>\n"
  end

  def short_element_xml_and_att_string(element, att_string)
    "#{tabs}<#{element} #{att_string}/>\n"
  end

  # requires that obj have attribute '@xml_element_name'
  # displays all *instance_variables* (does not call methods!)
  def short_element_xml_from_instance_vars(element_name)
    string = instance_variables.map{|v| "#{v[1..-1]}=\"#{instance_variable_get(v)}\"" }.join(' ')
    "#{tabs}<#{element_name} #{string}/>\n"
  end

  # takes an element as a symbol and returns the 
  def element_xml_no_atts(element)
    start = "#{tabs}<#{element}>\n"
    $DEPTH += 1
    if block_given? ; middle = yield else ; middle = '' end
    $DEPTH -= 1
    start + middle + "#{tabs}</#{element}>\n"
  end

  # takes an element as a symbol and returns the 
  def element_xml(element, att_list)

    start = "#{tabs}<#{element} #{attrs_xml(att_list)}>\n"
    $DEPTH += 1
    if block_given? ; middle = yield else ; middle = '' end
    $DEPTH -= 1
    start + middle + "#{tabs}</#{element}>\n"
  end

  # element as symbol and att_string as attributes
  # takes a block of whatever
  def element_xml_and_att_string(element, att_string)
    start = "#{tabs}<#{element} #{att_string}>\n"
    $DEPTH += 1
    if block_given? ; middle = yield else ; middle = '' end
    $DEPTH -= 1
    start + middle + "#{tabs}</#{element}>\n"
  end

  def attr_xml(symbol)
    "#{symbol}=\"#{send(symbol)}\""
  end

  def attrs_xml(list_of_symbols)
    list_of_symbols.collect {|sy| attr_xml(sy) }.join(" ")
  end

end

