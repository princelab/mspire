
require 'mspire/plms1'

module Mspire
  class Mzml
    # will use scan numbers if use_scan_nums is true, otherwise it will use index
    # numbers in place of scan nums
    def to_plms1(use_scan_nums=true)
      spectrum_index_list = self.index_list[:spectrum]
      scan_nums = 
        if use_scan_nums 
          spectrum_index_list.create_scan_to_index.keys
        else
          (0...spectrum_index_list.size).to_a
        end
      retention_times = self.enum_for(:each_spectrum_node).map do |xml_node|
        rt_xml_node=xml_node.xpath("scanList/scan/cvParam[@accession='MS:1000016']")[0]
        raise 'no retention time xml node' unless rt_xml_node
        retention_time = rt_xml_node['value'].to_f
        case rt_xml_node['unitName']
        when 'minute'
          retention_time * 60
        when 'second'
          retention_time
        else
          raise 'retention time must be in minutes or seconds (or add some code to handle)'
        end
      end
      # plms1 only requires that the obect respond to :each, giving a spectrum
      # object, so an Mzml object will work.
      Mspire::Plms1.new(scan_nums, retention_times, self)
    end
  end
end
