
#taken from rails, will be in Ruby 1.9
module Enumerable
  def group_by
    inject({}) do |groups, element|
      (groups[yield(element)] ||= []) << element
      groups
    end
  end
end
