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

  def test_before_data_falls_back_to_polynomial
    result = IERS::DeltaT.at(mjd: 41683.0)

    assert_equal :estimated, result.source
  end

  def test_fallback_is_symmetric_around_the_series
    before = IERS::DeltaT.at(mjd: 41683.0)
    after = IERS::DeltaT.at(mjd: 41694.0)

    assert_equal before.source, after.source
  end

  def test_after_data_falls_back_to_polynomial
    result = IERS::DeltaT.at(mjd: 41694.0)

    assert_equal :estimated, result.source
  end

  def test_after_polynomial_range_raises_out_of_range_error
    assert_raises(IERS::OutOfRangeError) do
      IERS::DeltaT.at(Date.new(1990, 1, 1))
    end
  end
end

class TestDeltaTSeriesGap < Minitest::Test
  # The bundled EOP series starts at MJD 41684 (1973-01-02), but the modern
  # UTC era starts at MJD 41317 (1972-01-01). Every date in between is covered
  # by the polynomial rather than left without an answer.
  SERIES_START_MJD = 41684.0

  def teardown
    IERS.reset_configuration!
  end

  def test_first_day_of_1972_is_estimated
    result = IERS::DeltaT.at(mjd: 41317.0)

    assert_equal :estimated, result.source
  end

  def test_mid_1972_is_estimated
    result = IERS::DeltaT.at(Date.new(1972, 7, 1))

    assert_equal :estimated, result.source
  end

  def test_day_before_series_start_is_estimated
    result = IERS::DeltaT.at(mjd: SERIES_START_MJD - 1)

    assert_equal :estimated, result.source
  end

  def test_series_start_is_measured
    result = IERS::DeltaT.at(mjd: SERIES_START_MJD)

    assert_equal :measured, result.source
  end

  def test_every_day_of_1972_has_a_value
    (41317..41683).each do |mjd|
      assert_instance_of Float, IERS::DeltaT.at(mjd: mjd.to_f).delta_t
    end
  end

  def test_step_at_the_seam_is_small
    # The polynomial and the series disagree by ~61 ms where they meet, well
    # inside the polynomial's own error in this era.
    before = IERS::DeltaT.at(mjd: SERIES_START_MJD - 0.5).delta_t
    after = IERS::DeltaT.at(mjd: SERIES_START_MJD).delta_t

    assert_in_delta before, after, 0.1
  end
end

class TestDeltaTEstimated < Minitest::Test
  def teardown
    IERS.reset_configuration!
  end

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

class TestDeltaTTruncatedSeries < Minitest::Test
  # A finals file that starts after the polynomial's 1986 cutoff leaves a real
  # gap, which must be reported as a DeltaT problem rather than an EOP one.
  def setup
    IERS.configure do |config|
      config.finals_path = fixture_path("finals_leap_boundary.dat")
      config.leap_second_path = fixture_path("leap_second_query.dat")
    end
  end

  def teardown
    IERS.reset_configuration!
  end

  def fixture_path(name)
    Pathname(__dir__).join("fixtures", name)
  end

  def test_within_polynomial_range_is_still_estimated
    result = IERS::DeltaT.at(Date.new(1900, 1, 1))

    assert_equal :estimated, result.source
  end

  def test_after_polynomial_range_raises_out_of_range_error
    assert_raises(IERS::OutOfRangeError) do
      IERS::DeltaT.at(Date.new(1990, 1, 1))
    end
  end

  def test_error_message_names_delta_t_not_the_eop_series
    error = assert_raises(IERS::OutOfRangeError) do
      IERS::DeltaT.at(Date.new(1990, 1, 1))
    end

    assert_match(/DeltaT/, error.message)
    assert_match(/1986/, error.message)
    assert_match(/EOP series/, error.message)
  end
end

class TestDeltaTEmptySeries < Minitest::Test
  # An unparseable or truncated finals file must not take the polynomial down
  # with it: dates before 1986 never needed the EOP series to begin with.
  def setup
    @empty = Tempfile.new(["finals_empty", ".dat"])

    IERS.configure do |config|
      config.finals_path = Pathname(@empty.path)
    end
  end

  def teardown
    IERS.reset_configuration!
    @empty.close!
  end

  def test_polynomial_still_answers
    result = IERS::DeltaT.at(Date.new(1900, 1, 1))

    assert_equal :estimated, result.source
  end

  def test_after_polynomial_range_raises_out_of_range_error
    error = assert_raises(IERS::OutOfRangeError) do
      IERS::DeltaT.at(Date.new(1990, 1, 1))
    end

    assert_nil error.available_range
  end
end
