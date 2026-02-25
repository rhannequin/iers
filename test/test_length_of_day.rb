# frozen_string_literal: true

require "test_helper"

class TestLengthOfDayEntry < Minitest::Test
  def test_has_length_of_day
    entry = IERS::LengthOfDay::Entry.new(
      length_of_day: 0.0028,
      mjd: 41687.0,
      data_quality: :observed
    )

    assert_in_delta 0.0028, entry.length_of_day
  end

  def test_length_of_day_is_float
    entry = IERS::LengthOfDay::Entry.new(
      length_of_day: 0.0028,
      mjd: 41687.0,
      data_quality: :observed
    )

    assert_instance_of Float, entry.length_of_day
  end

  def test_has_mjd
    entry = IERS::LengthOfDay::Entry.new(
      length_of_day: 0.0028,
      mjd: 41687.0,
      data_quality: :observed
    )

    assert_in_delta 41687.0, entry.mjd
  end

  def test_has_data_quality
    entry = IERS::LengthOfDay::Entry.new(
      length_of_day: 0.0028,
      mjd: 41687.0,
      data_quality: :observed
    )

    assert_equal :observed, entry.data_quality
  end

  def test_observed_predicate
    entry = IERS::LengthOfDay::Entry.new(
      length_of_day: 0.0028,
      mjd: 41687.0,
      data_quality: :observed
    )

    assert_predicate entry, :observed?
  end

  def test_predicted_predicate
    entry = IERS::LengthOfDay::Entry.new(
      length_of_day: 0.0028,
      mjd: 41687.0,
      data_quality: :predicted
    )

    assert_predicate entry, :predicted?
  end

  def test_is_frozen
    entry = IERS::LengthOfDay::Entry.new(
      length_of_day: 0.0028,
      mjd: 41687.0,
      data_quality: :observed
    )

    assert_predicate entry, :frozen?
  end
end

class TestLengthOfDayAt < Minitest::Test
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
    result = IERS::LengthOfDay.at(mjd: 41687.0)

    assert_instance_of Float, result
  end

  def test_on_exact_grid_point
    result = IERS::LengthOfDay.at(mjd: 41687.0)

    assert_in_delta 0.0028, result, 1e-6
  end

  def test_between_grid_points
    result = IERS::LengthOfDay.at(mjd: 41687.5)

    assert_in_delta 0.00285, result, 1e-4
  end

  def test_with_time_object
    result = IERS::LengthOfDay.at(Time.utc(1973, 1, 5))

    assert_instance_of Float, result
  end

  def test_with_date_object
    result = IERS::LengthOfDay.at(Date.new(1973, 1, 5))

    assert_in_delta 0.0028, result, 1e-6
  end

  def test_before_data_raises_out_of_range_error
    assert_raises(IERS::OutOfRangeError) do
      IERS::LengthOfDay.at(mjd: 41683.0)
    end
  end

  def test_after_data_raises_out_of_range_error
    assert_raises(IERS::OutOfRangeError) do
      IERS::LengthOfDay.at(mjd: 41694.0)
    end
  end

  def test_detailed_at_returns_entry
    result = IERS::LengthOfDay.detailed_at(mjd: 41687.0)

    assert_instance_of IERS::LengthOfDay::Entry, result
  end

  def test_detailed_at_has_query_mjd
    result = IERS::LengthOfDay.detailed_at(mjd: 41687.5)

    assert_in_delta 41687.5, result.mjd
  end

  def test_detailed_at_length_of_day_matches_at
    scalar = IERS::LengthOfDay.at(mjd: 41687.5)
    entry = IERS::LengthOfDay.detailed_at(mjd: 41687.5)

    assert_in_delta scalar, entry.length_of_day
  end
end

class TestLengthOfDayDataQuality < Minitest::Test
  def setup
    IERS.configure do |config|
      config.finals_path = fixture_path("finals_lod_mixed.dat")
      config.leap_second_path = fixture_path("leap_second_query.dat")
    end
  end

  def teardown
    IERS.reset_configuration!
  end

  def fixture_path(name)
    Pathname(__dir__).join("fixtures", name)
  end

  def test_observed_data_is_observed
    result = IERS::LengthOfDay.detailed_at(mjd: 41685.5)

    assert_predicate result, :observed?
  end

  def test_predicted_data_is_predicted
    result = IERS::LengthOfDay.detailed_at(mjd: 41688.5)

    assert_predicate result, :predicted?
  end

  def test_crossing_boundary_is_predicted
    result = IERS::LengthOfDay.detailed_at(mjd: 41687.5)

    assert_predicate result, :predicted?
  end

  def test_observed_value
    result = IERS::LengthOfDay.at(mjd: 41687.0)

    assert_in_delta 0.0028, result, 1e-6
  end

  def test_predicted_value
    result = IERS::LengthOfDay.at(mjd: 41688.0)

    assert_in_delta 0.0029, result, 1e-6
  end
end
