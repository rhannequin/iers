# frozen_string_literal: true

require "test_helper"
require "stringio"

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

  def test_to_date_converts_mjd
    result = IERS::TimeScale.to_date(41317.0)

    assert_equal Date.new(1972, 1, 1), result
  end

  def test_to_date_with_fractional_mjd
    result = IERS::TimeScale.to_date(41317.5)

    assert_equal Date.new(1972, 1, 1), result
  end

  # Kernel#Float writes "Integer out of Float range" to stderr for a magnitude
  # that does not fit one, and a library has no business writing there. The
  # value is unchanged: it was an Infinity before and it is one now.
  def test_a_date_too_large_for_a_float_converts_without_warning
    warnings = capture_warnings do
      assert_predicate IERS::TimeScale.to_mjd(mjd: 10**400), :infinite?
    end

    assert_empty warnings
  end

  def test_a_rational_date_too_large_for_a_float_converts_without_warning
    warnings = capture_warnings do
      converted = IERS::TimeScale.to_mjd(mjd: Rational(10**400))

      assert_predicate converted, :infinite?
    end

    assert_empty warnings
  end

  # The other direction warns too, because Kernel#Float reads the numerator
  # and the denominator.
  def test_a_rational_date_too_small_for_a_float_converts_without_warning
    warnings = capture_warnings do
      assert_in_delta 0.0, IERS::TimeScale.to_mjd(mjd: Rational(1, 10**400))
    end

    assert_empty warnings
  end

  def test_a_negative_date_too_large_for_a_float_keeps_its_sign
    assert_operator IERS::TimeScale.to_mjd(mjd: -(10**400)), :<, 0
  end

  def test_it_still_refuses_something_that_is_not_a_date
    assert_raises(ArgumentError) { IERS::TimeScale.to_mjd(mjd: "abc") }
    assert_raises(TypeError) { IERS::TimeScale.to_mjd(mjd: :soon) }
  end

  private

  # Whatever the block wrote to stderr, with warnings turned on, since this is
  # one Ruby only mentions in verbose mode.
  #
  # @return [String]
  def capture_warnings
    original, verbose = $stderr, $VERBOSE
    $stderr = StringIO.new
    $VERBOSE = true

    begin
      yield
      $stderr.string
    ensure
      $stderr = original
      $VERBOSE = verbose
    end
  end
end
