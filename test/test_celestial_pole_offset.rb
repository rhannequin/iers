# frozen_string_literal: true

require "test_helper"

class TestCelestialPoleOffsetEntry < Minitest::Test
  def test_has_x
    entry = IERS::CelestialPoleOffset::Entry.new(
      x: -18.637,
      y: -3.667,
      mjd: 41684.0,
      data_quality: :observed
    )

    assert_in_delta(-18.637, entry.x)
  end

  def test_has_y
    entry = IERS::CelestialPoleOffset::Entry.new(
      x: -18.637,
      y: -3.667,
      mjd: 41684.0,
      data_quality: :observed
    )

    assert_in_delta(-3.667, entry.y)
  end

  def test_has_mjd
    entry = IERS::CelestialPoleOffset::Entry.new(
      x: -18.637,
      y: -3.667,
      mjd: 41684.0,
      data_quality: :observed
    )

    assert_in_delta 41684.0, entry.mjd
  end

  def test_has_data_quality
    entry = IERS::CelestialPoleOffset::Entry.new(
      x: -18.637,
      y: -3.667,
      mjd: 41684.0,
      data_quality: :observed
    )

    assert_equal :observed, entry.data_quality
  end

  def test_observed_predicate
    entry = IERS::CelestialPoleOffset::Entry.new(
      x: -18.637,
      y: -3.667,
      mjd: 41684.0,
      data_quality: :observed
    )

    assert_predicate entry, :observed?
  end

  def test_predicted_predicate
    entry = IERS::CelestialPoleOffset::Entry.new(
      x: -18.637,
      y: -3.667,
      mjd: 41684.0,
      data_quality: :predicted
    )

    assert_predicate entry, :predicted?
  end

  def test_is_frozen
    entry = IERS::CelestialPoleOffset::Entry.new(
      x: -18.637,
      y: -3.667,
      mjd: 41684.0,
      data_quality: :observed
    )

    assert_predicate entry, :frozen?
  end
end

class TestCelestialPoleOffsetAt < Minitest::Test
  def setup
    IERS.configure do |config|
      config.finals_path = fixture_path("finals_10_days.dat")
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

  def test_returns_entry_instance
    result = IERS::CelestialPoleOffset.at(mjd: 41687.5)

    assert_instance_of IERS::CelestialPoleOffset::Entry, result
  end

  def test_entry_x_is_float
    result = IERS::CelestialPoleOffset.at(mjd: 41687.5)

    assert_instance_of Float, result.x
  end

  def test_entry_y_is_float
    result = IERS::CelestialPoleOffset.at(mjd: 41687.5)

    assert_instance_of Float, result.y
  end

  def test_entry_has_query_mjd
    result = IERS::CelestialPoleOffset.at(mjd: 41687.5)

    assert_in_delta 41687.5, result.mjd
  end

  def test_on_exact_grid_point_prefers_bulletin_b_x
    result = IERS::CelestialPoleOffset.at(mjd: 41684.0)

    assert_in_delta(-18.637, result.x, 1e-4)
  end

  def test_on_exact_grid_point_prefers_bulletin_b_y
    result = IERS::CelestialPoleOffset.at(mjd: 41684.0)

    assert_in_delta(-3.667, result.y, 1e-4)
  end

  def test_between_grid_points_x
    result = IERS::CelestialPoleOffset.at(mjd: 41687.5)

    assert_in_delta(-18.715, result.x, 0.1)
  end

  def test_between_grid_points_y
    result = IERS::CelestialPoleOffset.at(mjd: 41687.5)

    assert_in_delta(-3.665, result.y, 0.1)
  end

  def test_with_time_object
    result = IERS::CelestialPoleOffset.at(Time.utc(1973, 1, 5))

    assert_in_delta(-18.700, result.x, 0.1)
  end

  def test_with_date_object
    result = IERS::CelestialPoleOffset.at(Date.new(1973, 1, 5))

    assert_in_delta(-3.650, result.y, 0.1)
  end

  def test_before_data_raises_out_of_range_error
    error = assert_raises(IERS::OutOfRangeError) do
      IERS::CelestialPoleOffset.at(mjd: 41683.0)
    end

    assert_in_delta 41683.0, error.requested_mjd
    assert_equal 41684.0..41693.0, error.available_range
  end

  def test_after_data_raises_out_of_range_error
    assert_raises(IERS::OutOfRangeError) do
      IERS::CelestialPoleOffset.at(mjd: 41694.0)
    end
  end
end

class TestCelestialPoleOffsetDataQuality < Minitest::Test
  def setup
    IERS.configure do |config|
      config.finals_path = fixture_path(
        "finals_nutation_mixed.dat"
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

  def test_observed_data_is_observed
    result = IERS::CelestialPoleOffset.at(mjd: 41685.5)

    assert_predicate result, :observed?
  end

  def test_predicted_data_is_predicted
    result = IERS::CelestialPoleOffset.at(mjd: 41688.5)

    assert_predicate result, :predicted?
  end

  def test_crossing_boundary_is_predicted
    result = IERS::CelestialPoleOffset.at(mjd: 41687.5)

    assert_predicate result, :predicted?
  end

  def test_observed_uses_bulletin_b_x
    result = IERS::CelestialPoleOffset.at(mjd: 41684.0)

    assert_in_delta(-18.637, result.x, 1e-4)
  end

  def test_predicted_falls_back_to_series_a
    result = IERS::CelestialPoleOffset.at(mjd: 41688.0)

    assert_in_delta(-0.712, result.x, 1e-4)
  end
end

class TestCelestialPoleOffsetBetween < Minitest::Test
  def setup
    IERS.configure do |config|
      config.finals_path = fixture_path("finals_10_days.dat")
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

  def test_returns_array_of_entries
    results = IERS::CelestialPoleOffset.between(
      Date.new(1973, 1, 3),
      Date.new(1973, 1, 5)
    )

    assert_instance_of IERS::CelestialPoleOffset::Entry, results.first
  end

  def test_correct_count_for_date_range
    results = IERS::CelestialPoleOffset.between(
      Date.new(1973, 1, 3),
      Date.new(1973, 1, 7)
    )

    assert_equal 5, results.size
  end

  def test_first_entry_mjd
    results = IERS::CelestialPoleOffset.between(
      Date.new(1973, 1, 3),
      Date.new(1973, 1, 7)
    )

    assert_in_delta 41685.0, results.first.mjd
  end

  def test_last_entry_mjd
    results = IERS::CelestialPoleOffset.between(
      Date.new(1973, 1, 3),
      Date.new(1973, 1, 7)
    )

    assert_in_delta 41689.0, results.last.mjd
  end

  def test_entries_have_x_and_y
    results = IERS::CelestialPoleOffset.between(
      Date.new(1973, 1, 3),
      Date.new(1973, 1, 5)
    )

    assert_instance_of Float, results.first.x
    assert_instance_of Float, results.first.y
  end

  def test_entries_have_data_quality
    results = IERS::CelestialPoleOffset.between(
      Date.new(1973, 1, 3),
      Date.new(1973, 1, 5)
    )

    assert_equal :predicted, results.first.data_quality
  end

  def test_empty_array_for_out_of_data_range
    results = IERS::CelestialPoleOffset.between(
      Date.new(1980, 1, 1),
      Date.new(1980, 1, 5)
    )

    assert_empty results
  end

  def test_single_day_range
    results = IERS::CelestialPoleOffset.between(
      Date.new(1973, 1, 5),
      Date.new(1973, 1, 5)
    )

    assert_equal 1, results.size
  end

  def test_returns_frozen_array
    results = IERS::CelestialPoleOffset.between(
      Date.new(1973, 1, 3),
      Date.new(1973, 1, 5)
    )

    assert_predicate results, :frozen?
  end

  def test_between_uses_bulletin_b
    results = IERS::CelestialPoleOffset.between(
      Date.new(1973, 1, 2),
      Date.new(1973, 1, 2)
    )

    assert_in_delta(-18.637, results.first.x, 1e-4)
    assert_in_delta(-3.667, results.first.y, 1e-4)
  end
end
