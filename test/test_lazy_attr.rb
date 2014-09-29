require 'test/unit'
require 'roo/Roo'

class AAAA
  include Roo

  has data: {
    is: :ro,
    default: 100
  }

  has data1: {
    is: :ro,
    lazy: true,
    default: lambda {
      10 * self.data
    }
  }

end

class LazyAttrsTest < Test::Unit::TestCase

  def test_read
    assert_equal 100, AAAA.new.data
    assert_equal 1000, AAAA.new.data1
  end

end
