
module Enumerable
  # File activesupport/lib/active_support/core_ext/enumerable.rb, line 94
  def index_by
    return to_enum :index_by unless block_given?
    Hash[map { |elem| [yield(elem), elem] }]
  end
end
