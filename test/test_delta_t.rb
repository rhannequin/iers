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

  def test_returns_float
    result = IERS::DeltaT.at(mjd: 41687.0)

    assert_instance_of Float, result
  end

  def test_value_at_grid_point
    # TAI-UTC=12, TT-TAI=32.184, BB UT1-UTC=0.7990000
    # DeltaT = 12 + 32.184 - 0.799 = 43.385
    result = IERS::DeltaT.at(mjd: 41687.0)

    assert_in_delta 43.385, result, 1e-3
  end

  def test_value_between_grid_points
    result = IERS::DeltaT.at(mjd: 41687.5)

    assert_in_delta 43.385, result, 0.01
  end

  def test_with_time_object
    result = IERS::DeltaT.at(Time.utc(1973, 1, 5))

    assert_instance_of Float, result
  end

  def test_with_date_object
    result = IERS::DeltaT.at(Date.new(1973, 1, 5))

    assert_in_delta 43.385, result, 1e-3
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

  def test_pre_1972_raises_out_of_range_error
    assert_raises(IERS::OutOfRangeError) do
      IERS::DeltaT.at(mjd: 41316.0)
    end
  end
end
