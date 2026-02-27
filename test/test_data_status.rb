# frozen_string_literal: true

require "test_helper"

class TestDataStatus < Minitest::Test
  def test_bundled_source
    status = IERS::DataStatus.new(source: :bundled, cache_age: nil)

    assert_equal :bundled, status.source
  end

  def test_bundled_is_bundled
    status = IERS::DataStatus.new(source: :bundled, cache_age: nil)

    assert_predicate status, :bundled?
  end

  def test_bundled_is_not_cached
    status = IERS::DataStatus.new(source: :bundled, cache_age: nil)

    refute_predicate status, :cached?
  end

  def test_bundled_is_not_custom
    status = IERS::DataStatus.new(source: :bundled, cache_age: nil)

    refute_predicate status, :custom?
  end

  def test_cached_source
    status = IERS::DataStatus.new(source: :cached, cache_age: 3600)

    assert_equal :cached, status.source
  end

  def test_cached_is_cached
    status = IERS::DataStatus.new(source: :cached, cache_age: 3600)

    assert_predicate status, :cached?
  end

  def test_cached_is_not_bundled
    status = IERS::DataStatus.new(source: :cached, cache_age: 3600)

    refute_predicate status, :bundled?
  end

  def test_cached_is_not_custom
    status = IERS::DataStatus.new(source: :cached, cache_age: 3600)

    refute_predicate status, :custom?
  end

  def test_cached_exposes_cache_age
    status = IERS::DataStatus.new(source: :cached, cache_age: 3600)

    assert_equal 3600, status.cache_age
  end

  def test_custom_source
    status = IERS::DataStatus.new(source: :custom, cache_age: nil)

    assert_equal :custom, status.source
  end

  def test_custom_is_custom
    status = IERS::DataStatus.new(source: :custom, cache_age: nil)

    assert_predicate status, :custom?
  end

  def test_custom_is_not_cached
    status = IERS::DataStatus.new(source: :custom, cache_age: nil)

    refute_predicate status, :cached?
  end

  def test_custom_is_not_bundled
    status = IERS::DataStatus.new(source: :custom, cache_age: nil)

    refute_predicate status, :bundled?
  end
end
