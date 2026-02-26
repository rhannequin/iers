# frozen_string_literal: true

require "test_helper"

class TestUT1Entry < Minitest::Test
  def test_has_ut1_utc
    entry = IERS::UT1::Entry.new(
      ut1_utc: 0.123,
      mjd: 41684.0,
      data_quality: :observed
    )

    assert_in_delta 0.123, entry.ut1_utc
  end

  def test_has_mjd
    entry = IERS::UT1::Entry.new(
      ut1_utc: 0.123,
      mjd: 41684.0,
      data_quality: :observed
    )

    assert_in_delta 41684.0, entry.mjd
  end

  def test_has_data_quality
    entry = IERS::UT1::Entry.new(
      ut1_utc: 0.123,
      mjd: 41684.0,
      data_quality: :observed
    )

    assert_equal :observed, entry.data_quality
  end

  def test_observed_predicate
    entry = IERS::UT1::Entry.new(
      ut1_utc: 0.123,
      mjd: 41684.0,
      data_quality: :observed
    )

    assert_predicate entry, :observed?
  end

  def test_predicted_predicate
    entry = IERS::UT1::Entry.new(
      ut1_utc: 0.123,
      mjd: 41684.0,
      data_quality: :predicted
    )

    assert_predicate entry, :predicted?
  end

  def test_date_returns_date
    entry = IERS::UT1::Entry.new(
      ut1_utc: 0.123,
      mjd: 41684.0,
      data_quality: :observed
    )

    assert_equal Date.new(1973, 1, 2), entry.date
  end

  def test_is_frozen
    entry = IERS::UT1::Entry.new(
      ut1_utc: 0.123,
      mjd: 41684.0,
      data_quality: :observed
    )

    assert_predicate entry, :frozen?
  end
end

class TestUT1At < Minitest::Test
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
    assert_instance_of IERS::UT1::Entry, IERS::UT1.at(mjd: 41687.5)
  end

  def test_on_exact_grid_point_prefers_bulletin_b
    assert_in_delta 0.8075, IERS::UT1.at(mjd: 41684.0).ut1_utc, 1e-4
  end

  def test_between_grid_points
    result = IERS::UT1.at(mjd: 41687.5).ut1_utc

    assert_operator result, :>, 0.796
    assert_operator result, :<, 0.799
  end

  def test_with_time_object
    result = IERS::UT1.at(Time.utc(1973, 1, 5))

    assert_in_delta 0.799, result.ut1_utc, 1e-3
  end

  def test_with_date_object
    result = IERS::UT1.at(Date.new(1973, 1, 5))

    assert_in_delta 0.799, result.ut1_utc, 1e-3
  end

  def test_before_data_raises_out_of_range_error
    error = assert_raises(IERS::OutOfRangeError) do
      IERS::UT1.at(mjd: 41683.0)
    end

    assert_in_delta 41683.0, error.requested_mjd
    assert_equal 41684.0..41693.0, error.available_range
  end

  def test_after_data_raises_out_of_range_error
    assert_raises(IERS::OutOfRangeError) do
      IERS::UT1.at(mjd: 41694.0)
    end
  end
end

class TestUT1AtDataQuality < Minitest::Test
  def setup
    IERS.configure do |config|
      config.finals_path = fixture_path("finals_mixed_ip.dat")
      config.leap_second_path = fixture_path("leap_second_query.dat")
    end
  end

  def teardown
    IERS.reset_configuration!
  end

  def fixture_path(name)
    Pathname(__dir__).join("fixtures", name)
  end

  def test_returns_entry_instance
    result = IERS::UT1.at(mjd: 41685.5)

    assert_instance_of IERS::UT1::Entry, result
  end

  def test_entry_has_ut1_utc_float
    result = IERS::UT1.at(mjd: 41685.5)

    assert_instance_of Float, result.ut1_utc
  end

  def test_entry_has_query_mjd
    result = IERS::UT1.at(mjd: 41685.5)

    assert_in_delta 41685.5, result.mjd
  end

  def test_observed_data_is_observed
    result = IERS::UT1.at(mjd: 41685.5)

    assert_predicate result, :observed?
  end

  def test_predicted_data_is_predicted
    result = IERS::UT1.at(mjd: 41688.5)

    assert_predicate result, :predicted?
  end

  def test_crossing_boundary_is_predicted
    result = IERS::UT1.at(mjd: 41687.5)

    assert_predicate result, :predicted?
  end

  def test_accepts_time_object
    result = IERS::UT1.at(Time.utc(1973, 1, 4))

    assert_instance_of IERS::UT1::Entry, result
  end

  def test_observed_data_uses_bulletin_b
    result = IERS::UT1.at(mjd: 41684.0)

    assert_in_delta 0.8075, result.ut1_utc, 1e-4
  end

  def test_predicted_data_falls_back_to_series_a
    result = IERS::UT1.at(mjd: 41688.5)

    assert_operator result.ut1_utc.abs, :>, 0
  end

  def test_out_of_range_raises_error
    assert_raises(IERS::OutOfRangeError) do
      IERS::UT1.at(mjd: 41683.0)
    end
  end
end

class TestUT1Between < Minitest::Test
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

  def test_returns_lazy_enumerator
    results = IERS::UT1.between(
      Date.new(1973, 1, 3),
      Date.new(1973, 1, 5)
    )

    assert_instance_of Enumerator::Lazy, results
  end

  def test_yields_entries
    results = IERS::UT1.between(
      Date.new(1973, 1, 3),
      Date.new(1973, 1, 5)
    )

    assert_instance_of IERS::UT1::Entry, results.first
  end

  def test_correct_count_for_date_range
    results = IERS::UT1.between(
      Date.new(1973, 1, 3),
      Date.new(1973, 1, 7)
    )

    assert_equal 5, results.count
  end

  def test_first_entry_mjd
    results = IERS::UT1.between(
      Date.new(1973, 1, 3),
      Date.new(1973, 1, 7)
    )

    assert_in_delta 41685.0, results.first.mjd
  end

  def test_last_entry_mjd
    results = IERS::UT1.between(
      Date.new(1973, 1, 3),
      Date.new(1973, 1, 7)
    )

    assert_in_delta 41689.0, results.to_a.last.mjd
  end

  def test_entries_have_ut1_utc
    results = IERS::UT1.between(
      Date.new(1973, 1, 3),
      Date.new(1973, 1, 5)
    )

    assert_instance_of Float, results.first.ut1_utc
  end

  def test_entries_have_data_quality
    results = IERS::UT1.between(
      Date.new(1973, 1, 3),
      Date.new(1973, 1, 5)
    )

    assert_equal :observed, results.first.data_quality
  end

  def test_empty_for_out_of_data_range
    results = IERS::UT1.between(
      Date.new(1980, 1, 1),
      Date.new(1980, 1, 5)
    )

    refute_predicate results, :any?
  end

  def test_single_day_range
    results = IERS::UT1.between(
      Date.new(1973, 1, 5),
      Date.new(1973, 1, 5)
    )

    assert_equal 1, results.count
  end

  def test_between_uses_bulletin_b_when_available
    results = IERS::UT1.between(
      Date.new(1973, 1, 2),
      Date.new(1973, 1, 2)
    )

    assert_in_delta 0.8075, results.first.ut1_utc, 1e-4
  end
end

class TestUT1InterpolationOverride < Minitest::Test
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

  def test_linear_override_returns_entry
    result = IERS::UT1.at(mjd: 41687.5, interpolation: :linear)

    assert_instance_of IERS::UT1::Entry, result
  end

  def test_linear_and_lagrange_produce_distinct_results
    linear = IERS::UT1.at(
      mjd: 41687.5,
      interpolation: :linear
    ).ut1_utc
    lagrange = IERS::UT1.at(
      mjd: 41687.5,
      interpolation: :lagrange
    ).ut1_utc

    refute_in_delta linear, lagrange, 1e-10
  end

  def test_override_does_not_mutate_global_config
    IERS::UT1.at(mjd: 41687.5, interpolation: :linear)

    assert_equal :lagrange, IERS.configuration.interpolation
  end

  def test_linear_at_midpoint_equals_average_of_neighbors
    # MJD 41687 -> 0.799 (Bulletin B), MJD 41688 -> 0.796
    expected = (0.799 + 0.796) / 2.0
    result = IERS::UT1.at(
      mjd: 41687.5,
      interpolation: :linear
    )

    assert_in_delta expected, result.ut1_utc, 1e-4
  end

  def test_global_linear_config_works
    IERS.configure { |c| c.interpolation = :linear }

    expected = (0.799 + 0.796) / 2.0
    result = IERS::UT1.at(mjd: 41687.5)

    assert_in_delta expected, result.ut1_utc, 1e-4
  end

  def test_global_linear_overridden_by_per_query_lagrange
    IERS.configure { |c| c.interpolation = :linear }

    linear = IERS::UT1.at(mjd: 41687.5).ut1_utc
    lagrange = IERS::UT1.at(
      mjd: 41687.5,
      interpolation: :lagrange
    ).ut1_utc

    refute_in_delta linear, lagrange, 1e-10
  end
end

class TestUT1LeapSecondBoundary < Minitest::Test
  def setup
    IERS.configure do |config|
      config.finals_path = fixture_path(
        "finals_leap_boundary.dat"
      )
      config.leap_second_path = fixture_path(
        "leap_second_query.dat"
      )
    end
  end

  def teardown
    IERS.reset_configuration!
  end

  def fixture_path(name)
    Pathname(__dir__).join("fixtures", name)
  end

  def test_midpoint_across_leap_second_is_negative
    result = IERS::UT1.at(mjd: 57753.5)

    assert_operator result.ut1_utc, :<, 0
  end

  def test_midpoint_matches_smooth_interpolation
    result = IERS::UT1.at(mjd: 57753.5)

    assert_in_delta(-0.4082, result.ut1_utc, 1e-3)
  end

  def test_exact_grid_after_leap_returns_tabulated_value
    result = IERS::UT1.at(mjd: 57754.0)

    assert_in_delta 0.5912821, result.ut1_utc, 1e-4
  end

  def test_away_from_boundary_still_works
    result = IERS::UT1.at(mjd: 57752.5)

    assert_in_delta(-0.4065, result.ut1_utc, 1e-3)
  end

  def test_linear_across_leap_second_boundary
    result = IERS::UT1.at(
      mjd: 57753.5,
      interpolation: :linear
    )

    assert_in_delta(-0.408, result.ut1_utc, 1e-2)
  end
end
