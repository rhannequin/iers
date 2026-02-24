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

    assert_equal "https://datacenter.iers.org/data/csv/finals2000A.all",
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
end
