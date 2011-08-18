# encoding: utf-8
$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'test/unit'
require 'when_sun'

class TestWhenSun < Test::Unit::TestCase

  def test_rise_20100308_pontassieve
    rise = WhenSun.calculate(:rise, Date.new(2010, 3, 8), 43.779, 11.432)
    assert_equal(rise.to_i, 1268026793)
  end

  def test_set_20100308_pontassieve
    rise = WhenSun.calculate(:set, Date.new(2010, 3, 8), 43.779, 11.432)
    assert_equal(rise.to_i, 1268068276)
  end

  def test_rise_helper
    rise = WhenSun.rise(Date.new(2010, 3, 8), 43.779, 11.432)
    assert_equal(rise.to_i, 1268026793)
  end

  def test_set_helper
    rise = WhenSun.set(Date.new(2010, 3, 8), 43.779, 11.432)
    assert_equal(rise.to_i, 1268068276)
  end

  def test_midnight_sun_on_20100621_north_cape
    rise = WhenSun.calculate(:rise, Date.new(2010, 6, 21), 71.170219, 25.785556)
    assert_nil(rise)
    set = WhenSun.calculate(:set, Date.new(2010, 6, 21), 71.170219, 25.785556)
    assert_nil(set)
  end

  def test_unknown_event
    assert_raise(RuntimeError) { WhenSun.calculate(:foo, Date.new(2010, 3, 8), 43.779, 11.432) }
  end

end