
require 'mspire/plms1'

module Mspire
  class Mzml
    # will use scan numbers if use_scan_nums is true (typically start with
    # one), otherwise it will use index numbers (starts with zero)
    def to_plms1(use_scan_nums=true)
      spectrum_index = self.index_list[:spectrum]

      scan_nums = spectrum_index.create_scan_to_index.keys if use_scan_nums

      spectra = []
      rts = []
      self.each_with_index do |spec, index|
        next unless spec.ms_level == 1
        nums << (use_scan_nums ? scan_nums[index] : index)
        spectra << spec
        rts << spec.retention_time
      end
      # plms1 only requires that the obect respond to :each, giving a spectrum
      # object, so an Mzml object will work.
      Mspire::Plms1.new(nums, rts, spectra)
    end
  end
end
