# frozen_string_literal: true

require "test_helper"

class TestEarthRotationAngleAt < Minitest::Test
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
    result = IERS::EarthRotationAngle.at(mjd: 41687.0)

    assert_instance_of Float, result
  end

  def test_non_negative
    result = IERS::EarthRotationAngle.at(mjd: 41687.0)

    assert_operator result, :>=, 0.0
  end

  def test_less_than_two_pi
    result = IERS::EarthRotationAngle.at(mjd: 41687.0)

    assert_operator result, :<, 2.0 * Math::PI
  end

  def test_with_mjd_keyword
    result = IERS::EarthRotationAngle.at(mjd: 41687.0)

    assert_instance_of Float, result
  end

  def test_with_jd_keyword
    result = IERS::EarthRotationAngle.at(
      jd: 41687.0 + 2_400_000.5
    )

    assert_instance_of Float, result
  end

  def test_with_time_object
    result = IERS::EarthRotationAngle.at(Time.utc(1973, 1, 5))

    assert_instance_of Float, result
  end

  def test_with_date_object
    result = IERS::EarthRotationAngle.at(Date.new(1973, 1, 5))

    assert_instance_of Float, result
  end

  def test_before_data_raises_out_of_range_error
    assert_raises(IERS::OutOfRangeError) do
      IERS::EarthRotationAngle.at(mjd: 41683.0)
    end
  end

  def test_after_data_raises_out_of_range_error
    assert_raises(IERS::OutOfRangeError) do
      IERS::EarthRotationAngle.at(mjd: 41694.0)
    end
  end
end

class TestEarthRotationAngleConsistency < Minitest::Test
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

  def test_consistent_with_manual_computation
    query_mjd = 41687.0
    ut1_utc = IERS::UT1.at(mjd: query_mjd).ut1_utc

    du = query_mjd - 51_544.5 + ut1_utc / 86_400.0
    turns = 0.7790572732640 + 1.00273781191135448 * du
    expected = (turns % 1.0) * 2.0 * Math::PI

    assert_in_delta expected,
      IERS::EarthRotationAngle.at(mjd: query_mjd), 1e-15
  end

  def test_consistent_at_interpolated_point
    query_mjd = 41687.5
    ut1_utc = IERS::UT1.at(mjd: query_mjd).ut1_utc

    du = query_mjd - 51_544.5 + ut1_utc / 86_400.0
    turns = 0.7790572732640 + 1.00273781191135448 * du
    expected = (turns % 1.0) * 2.0 * Math::PI

    assert_in_delta expected,
      IERS::EarthRotationAngle.at(mjd: query_mjd), 1e-15
  end
end
