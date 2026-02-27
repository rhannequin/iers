# frozen_string_literal: true

require "test_helper"

class TestTAIUtcToTai < Minitest::Test
  def setup
    IERS.configure do |config|
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
    result = IERS::TAI.utc_to_tai(mjd: 57754.0)

    assert_instance_of Float, result
  end

  def test_known_value
    # 2017-01-01 UTC, TAI-UTC = 37s
    utc_mjd = 57754.0
    expected = utc_mjd + 37.0 / 86_400.0

    assert_in_delta expected, IERS::TAI.utc_to_tai(mjd: utc_mjd), 1e-15
  end

  def test_with_time_object
    result = IERS::TAI.utc_to_tai(Time.utc(2017, 1, 1))

    assert_instance_of Float, result
  end

  def test_with_jd_keyword
    utc_mjd = 57754.0
    utc_jd = utc_mjd + 2_400_000.5

    assert_in_delta IERS::TAI.utc_to_tai(mjd: utc_mjd),
      IERS::TAI.utc_to_tai(jd: utc_jd), 1e-15
  end

  def test_different_offset_eras
    # 1973-01-05, TAI-UTC = 12s
    utc_mjd = 41687.0
    expected = utc_mjd + 12.0 / 86_400.0

    assert_in_delta expected, IERS::TAI.utc_to_tai(mjd: utc_mjd), 1e-15
  end

  def test_before_data_raises_out_of_range_error
    assert_raises(IERS::OutOfRangeError) do
      IERS::TAI.utc_to_tai(mjd: 41316.0)
    end
  end
end

class TestTAITaiToUtc < Minitest::Test
  def setup
    IERS.configure do |config|
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
    tai_mjd = 57754.0 + 37.0 / 86_400.0
    result = IERS::TAI.tai_to_utc(mjd: tai_mjd)

    assert_instance_of Float, result
  end

  def test_known_value
    # TAI instant corresponding to 2017-01-01 UTC
    utc_mjd = 57754.0
    tai_mjd = utc_mjd + 37.0 / 86_400.0

    assert_in_delta utc_mjd, IERS::TAI.tai_to_utc(mjd: tai_mjd), 1e-15
  end

  def test_different_offset_era
    # TAI instant corresponding to 1973-01-05 UTC
    utc_mjd = 41687.0
    tai_mjd = utc_mjd + 12.0 / 86_400.0

    assert_in_delta utc_mjd, IERS::TAI.tai_to_utc(mjd: tai_mjd), 1e-15
  end

  def test_roundtrip
    utc_mjd = 57754.0
    tai_mjd = IERS::TAI.utc_to_tai(mjd: utc_mjd)

    assert_in_delta utc_mjd, IERS::TAI.tai_to_utc(mjd: tai_mjd), 1e-15
  end

  def test_roundtrip_mid_era
    utc_mjd = 41687.5
    tai_mjd = IERS::TAI.utc_to_tai(mjd: utc_mjd)

    assert_in_delta utc_mjd, IERS::TAI.tai_to_utc(mjd: tai_mjd), 1e-15
  end

  def test_roundtrip_near_leap_second_boundary
    # Just after 2017-01-01 boundary, TAI-UTC = 37
    utc_mjd = 57754.0 + 1.0 / 86_400.0
    tai_mjd = IERS::TAI.utc_to_tai(mjd: utc_mjd)

    assert_in_delta utc_mjd, IERS::TAI.tai_to_utc(mjd: tai_mjd), 1e-15
  end
end
