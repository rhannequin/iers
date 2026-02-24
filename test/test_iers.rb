# frozen_string_literal: true

require "test_helper"

class TestIERS < Minitest::Test
  def teardown
    IERS.reset_configuration!
  end

  def test_that_it_has_a_version_number
    refute_nil ::IERS::VERSION
  end

  def test_configuration_returns_default_configuration
    assert_instance_of IERS::Configuration, IERS.configuration
  end

  def test_configure_yields_configuration
    IERS.configure do |config|
      assert_instance_of IERS::Configuration, config
    end
  end

  def test_configure_modifies_configuration
    IERS.configure do |config|
      config.download_timeout = 60
    end

    assert_equal 60, IERS.configuration.download_timeout
  end

  def test_reset_configuration_restores_defaults
    IERS.configure { |c| c.download_timeout = 99 }
    IERS.reset_configuration!

    assert_equal 30, IERS.configuration.download_timeout
  end

  def test_configuration_is_same_object_across_calls
    assert_same IERS.configuration, IERS.configuration
  end
end
