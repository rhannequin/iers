# frozen_string_literal: true

require "test_helper"

class TestGMSTAt < Minitest::Test
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
    result = IERS::GMST.at(mjd: 41687.0)

    assert_instance_of Float, result
  end

  def test_non_negative
    result = IERS::GMST.at(mjd: 41687.0)

    assert_operator result, :>=, 0.0
  end

  def test_less_than_two_pi
    result = IERS::GMST.at(mjd: 41687.0)

    assert_operator result, :<, 2.0 * Math::PI
  end

  def test_with_mjd_keyword
    result = IERS::GMST.at(mjd: 41687.0)

    assert_instance_of Float, result
  end

  def test_with_jd_keyword
    result = IERS::GMST.at(jd: 41687.0 + 2_400_000.5)

    assert_instance_of Float, result
  end

  def test_with_time_object
    result = IERS::GMST.at(Time.utc(1973, 1, 5))

    assert_instance_of Float, result
  end

  def test_with_date_object
    result = IERS::GMST.at(Date.new(1973, 1, 5))

    assert_instance_of Float, result
  end

  def test_before_data_raises_out_of_range_error
    assert_raises(IERS::OutOfRangeError) do
      IERS::GMST.at(mjd: 41683.0)
    end
  end

  def test_accepts_interpolation_keyword
    result = IERS::GMST.at(mjd: 41687.5, interpolation: :linear)

    assert_instance_of Float, result
  end
end

class TestGMSTConsistency < Minitest::Test
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
    era = IERS::EarthRotationAngle.at(mjd: query_mjd)

    tai_utc = IERS::LeapSecond.at(mjd: query_mjd)
    tt_mjd = query_mjd + (tai_utc + 32.184) / 86_400.0
    t = (tt_mjd - 51_544.5) / 36_525.0

    coeffs = [
      0.014506,
      4612.156534,
      1.3915817,
      -0.00000044,
      -0.000029956,
      -0.0000000368
    ]
    poly = coeffs.reverse.reduce { |acc, c| acc * t + c }
    arcsec_to_rad = Math::PI / 648_000.0
    expected = (era + poly * arcsec_to_rad) % (2.0 * Math::PI)

    assert_in_delta expected, IERS::GMST.at(mjd: query_mjd), 1e-15
  end

  def test_differs_from_era
    query_mjd = 41687.0
    era = IERS::EarthRotationAngle.at(mjd: query_mjd)
    gmst = IERS::GMST.at(mjd: query_mjd)

    refute_in_delta era, gmst, 1e-10
  end
end
