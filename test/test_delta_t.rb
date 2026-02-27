# frozen_string_literal: true

require "test_helper"

class TestDeltaTAt < Minitest::Test
  def setup
    IERS.configure do |config|
      config.finals_path = fixture_path("finals_10_days.dat")
      config.leap_second_path = fixture_path("leap_second_query.dat")
    end
  end

  def teardown
    IERS.reset_configuration!
  end

  def fixture_path(name)
    Pathname(__dir__).join("fixtures", name)
  end

  def test_returns_entry
    result = IERS::DeltaT.at(mjd: 41687.0)

    assert_instance_of IERS::DeltaT::Entry, result
  end

  def test_delta_t_is_float
    result = IERS::DeltaT.at(mjd: 41687.0)

    assert_instance_of Float, result.delta_t
  end

  def test_value_at_grid_point
    # TAI-UTC=12, TT-TAI=32.184, BB UT1-UTC=0.7990000
    # DeltaT = 12 + 32.184 - 0.799 = 43.385
    result = IERS::DeltaT.at(mjd: 41687.0)

    assert_in_delta 43.385, result.delta_t, 1e-3
  end

  def test_value_between_grid_points
    result = IERS::DeltaT.at(mjd: 41687.5)

    assert_in_delta 43.385, result.delta_t, 0.01
  end

  def test_with_time_object
    result = IERS::DeltaT.at(Time.utc(1973, 1, 5))

    assert_instance_of IERS::DeltaT::Entry, result
  end

  def test_with_date_object
    result = IERS::DeltaT.at(Date.new(1973, 1, 5))

    assert_in_delta 43.385, result.delta_t, 1e-3
  end

  def test_measured_source_for_post_1972
    result = IERS::DeltaT.at(mjd: 41687.0)

    assert_equal :measured, result.source
  end

  def test_measured_predicate
    result = IERS::DeltaT.at(mjd: 41687.0)

    assert_predicate result, :measured?
    refute_predicate result, :estimated?
  end

  def test_before_data_raises_out_of_range_error
    assert_raises(IERS::OutOfRangeError) do
      IERS::DeltaT.at(mjd: 41683.0)
    end
  end

  def test_after_data_raises_out_of_range_error
    assert_raises(IERS::OutOfRangeError) do
      IERS::DeltaT.at(mjd: 41694.0)
    end
  end
end

class TestDeltaTEstimated < Minitest::Test
  def test_returns_entry
    result = IERS::DeltaT.at(Date.new(1900, 1, 1))

    assert_instance_of IERS::DeltaT::Entry, result
  end

  def test_estimated_source
    result = IERS::DeltaT.at(Date.new(1900, 1, 1))

    assert_equal :estimated, result.source
  end

  def test_estimated_predicate
    result = IERS::DeltaT.at(Date.new(1900, 1, 1))

    assert_predicate result, :estimated?
    refute_predicate result, :measured?
  end

  def test_delta_t_is_float
    result = IERS::DeltaT.at(Date.new(1900, 1, 1))

    assert_instance_of Float, result.delta_t
  end

  def test_known_value_at_1900
    # At y=1900.0, t=0, polynomial constant term is -2.79
    result = IERS::DeltaT.at(Date.new(1900, 1, 1))

    assert_in_delta(-2.79, result.delta_t, 0.1)
  end

  def test_known_value_at_1950
    # At y=1950.0, t=0, polynomial constant term is 29.07
    result = IERS::DeltaT.at(Date.new(1950, 1, 1))

    assert_in_delta 29.07, result.delta_t, 0.1
  end

  def test_known_value_at_1820
    result = IERS::DeltaT.at(Date.new(1820, 1, 1))

    assert_in_delta 12.0, result.delta_t, 1.0
  end

  def test_before_1800_raises_out_of_range_error
    assert_raises(IERS::OutOfRangeError) do
      IERS::DeltaT.at(Date.new(1799, 6, 15))
    end
  end

  def test_before_1800_error_message
    error = assert_raises(IERS::OutOfRangeError) do
      IERS::DeltaT.at(Date.new(1799, 6, 15))
    end

    assert_match(/1800/, error.message)
  end
end

class TestDeltaTConsistency < Minitest::Test
  def setup
    IERS.configure do |config|
      config.finals_path = fixture_path("finals_10_days.dat")
      config.leap_second_path = fixture_path("leap_second_query.dat")
    end
  end

  def teardown
    IERS.reset_configuration!
  end

  def fixture_path(name)
    Pathname(__dir__).join("fixtures", name)
  end

  def test_consistent_with_components
    mjd = 41687.5
    tai_utc = IERS::LeapSecond.at(mjd: mjd)
    ut1_utc = IERS::UT1.at(mjd: mjd).ut1_utc
    expected = tai_utc + 32.184 - ut1_utc

    assert_in_delta expected, IERS::DeltaT.at(mjd: mjd).delta_t, 1e-10
  end
end
