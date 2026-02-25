# frozen_string_literal: true

require "test_helper"

class TestConfiguration < Minitest::Test
  def test_default_cache_dir
    config = IERS::Configuration.new

    assert_equal Pathname("~/.cache/iers").expand_path, config.cache_dir
  end

  def test_cache_dir_is_a_pathname
    config = IERS::Configuration.new

    assert_instance_of Pathname, config.cache_dir
  end

  def test_default_sources
    config = IERS::Configuration.new

    assert_equal "https://datacenter.iers.org/data/latestVersion/finals.all.iau2000.txt",
      config.sources[:finals]
    assert_equal "https://hpiers.obspm.fr/iers/bul/bulc/Leap_Second.dat",
      config.sources[:leap_seconds]
  end

  def test_default_download_timeout
    config = IERS::Configuration.new

    assert_equal 30, config.download_timeout
  end

  def test_default_finals_path_is_nil
    config = IERS::Configuration.new

    assert_nil config.finals_path
  end

  def test_default_leap_second_path_is_nil
    config = IERS::Configuration.new

    assert_nil config.leap_second_path
  end

  def test_cache_dir_assignment_coerces_string_to_pathname
    config = IERS::Configuration.new
    config.cache_dir = "/tmp/custom"

    assert_instance_of Pathname, config.cache_dir
    assert_equal Pathname("/tmp/custom"), config.cache_dir
  end

  def test_finals_path_assignment_coerces_to_pathname
    config = IERS::Configuration.new
    config.finals_path = "/opt/data/finals"

    assert_instance_of Pathname, config.finals_path
    assert_equal Pathname("/opt/data/finals"), config.finals_path
  end

  def test_leap_second_path_assignment_coerces_to_pathname
    config = IERS::Configuration.new
    config.leap_second_path = "/opt/data/leap"

    assert_instance_of Pathname, config.leap_second_path
    assert_equal Pathname("/opt/data/leap"), config.leap_second_path
  end

  def test_download_timeout_must_be_positive
    config = IERS::Configuration.new

    assert_raises(IERS::ConfigurationError) { config.download_timeout = 0 }
    assert_raises(IERS::ConfigurationError) { config.download_timeout = -1 }
  end

  def test_sources_must_be_a_hash
    config = IERS::Configuration.new

    assert_raises(IERS::ConfigurationError) { config.sources = "not a hash" }
  end

  def test_default_interpolation_is_lagrange
    config = IERS::Configuration.new

    assert_equal :lagrange, config.interpolation
  end

  def test_interpolation_can_be_set_to_linear
    config = IERS::Configuration.new
    config.interpolation = :linear

    assert_equal :linear, config.interpolation
  end

  def test_interpolation_rejects_unknown_method
    config = IERS::Configuration.new

    assert_raises(IERS::ConfigurationError) { config.interpolation = :cubic }
  end

  def test_default_lagrange_order_is_4
    config = IERS::Configuration.new

    assert_equal 4, config.lagrange_order
  end

  def test_lagrange_order_can_be_set_to_even_number
    config = IERS::Configuration.new
    config.lagrange_order = 6

    assert_equal 6, config.lagrange_order
  end

  def test_lagrange_order_rejects_odd_number
    config = IERS::Configuration.new

    assert_raises(IERS::ConfigurationError) { config.lagrange_order = 3 }
  end

  def test_lagrange_order_rejects_zero
    config = IERS::Configuration.new

    assert_raises(IERS::ConfigurationError) { config.lagrange_order = 0 }
  end

  def test_lagrange_order_rejects_negative
    config = IERS::Configuration.new

    assert_raises(IERS::ConfigurationError) { config.lagrange_order = -2 }
  end
end
