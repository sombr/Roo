require 'test/unit'
require 'roo/Roo'

class AAA
  include Roo

  has data: {
    is: :ro,
    default: 100
  }

  has data1: {
    is: :rw
  }

  has data2: {
    is: :rwp,
    default: 10
  }

  def set_data2
    self.data2 = 100
  end

  has data3: {
    is: :ro,
    default: lambda {
      10 * 100
    }
  }

end

class SimpleAttrsTest < Test::Unit::TestCase

  def test_read
    assert_equal 100, AAA.new.data
    assert_equal nil, AAA.new.data1
  end

  def test_write
    a = AAA.new
    a.data1 = 1000

    assert_equal 1000, a.data1
  end

  def test_private
    a = AAA.new
    assert_equal 10, a.data2

    begin
      a.data2 = 200
      assert_equal 10, a.data2 # should not pass
    rescue
      a.set_data2
      assert_equal 100, a.data2
    end
  end

  def test_builder
    a = AAA.new
    assert_equal 1000, a.data3
  end
end
