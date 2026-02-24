# frozen_string_literal: true

require "test_helper"

class TestTimeScale < Minitest::Test
  # MJD of 1972-01-01 = 41317.0
  # JD of 1972-01-01 at 0h UT = 2441317.5

  def test_converts_date_to_mjd
    result = IERS::TimeScale.to_mjd(Date.new(1972, 1, 1))

    assert_in_delta 41317.0, result
  end

  def test_converts_time_to_mjd
    result = IERS::TimeScale.to_mjd(Time.utc(1972, 1, 1))

    assert_in_delta 41317.0, result
  end

  def test_converts_datetime_to_mjd
    result = IERS::TimeScale.to_mjd(DateTime.new(1972, 1, 1))

    assert_in_delta 41317.0, result
  end

  def test_converts_time_with_hours_to_fractional_mjd
    result = IERS::TimeScale.to_mjd(Time.utc(1972, 1, 1, 12, 0, 0))

    assert_in_delta 41317.5, result
  end

  def test_converts_jd_keyword_to_mjd
    result = IERS::TimeScale.to_mjd(jd: 2441317.5)

    assert_in_delta 41317.0, result
  end

  def test_converts_mjd_keyword_passthrough
    result = IERS::TimeScale.to_mjd(mjd: 57754.0)

    assert_in_delta 57754.0, result
  end

  def test_returns_float
    result = IERS::TimeScale.to_mjd(Date.new(2017, 1, 1))

    assert_instance_of Float, result
  end

  def test_rejects_bare_float
    assert_raises(ArgumentError) do
      IERS::TimeScale.to_mjd(41317.0)
    end
  end

  def test_rejects_bare_integer
    assert_raises(ArgumentError) do
      IERS::TimeScale.to_mjd(41317)
    end
  end

  def test_rejects_string
    assert_raises(ArgumentError) do
      IERS::TimeScale.to_mjd("1972-01-01")
    end
  end

  def test_rejects_nil
    assert_raises(ArgumentError) do
      IERS::TimeScale.to_mjd(nil)
    end
  end
end
