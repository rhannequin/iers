# frozen_string_literal: true

require "test_helper"

class TestPolarMotionEntry < Minitest::Test
  def test_has_x
    entry = IERS::PolarMotion::Entry.new(
      x: 0.143,
      y: 0.137,
      mjd: 41684.0,
      data_quality: :observed
    )

    assert_in_delta 0.143, entry.x
  end

  def test_has_y
    entry = IERS::PolarMotion::Entry.new(
      x: 0.143,
      y: 0.137,
      mjd: 41684.0,
      data_quality: :observed
    )

    assert_in_delta 0.137, entry.y
  end

  def test_has_mjd
    entry = IERS::PolarMotion::Entry.new(
      x: 0.143,
      y: 0.137,
      mjd: 41684.0,
      data_quality: :observed
    )

    assert_in_delta 41684.0, entry.mjd
  end

  def test_has_data_quality
    entry = IERS::PolarMotion::Entry.new(
      x: 0.143,
      y: 0.137,
      mjd: 41684.0,
      data_quality: :observed
    )

    assert_equal :observed, entry.data_quality
  end

  def test_observed_predicate
    entry = IERS::PolarMotion::Entry.new(
      x: 0.143,
      y: 0.137,
      mjd: 41684.0,
      data_quality: :observed
    )

    assert_predicate entry, :observed?
  end

  def test_predicted_predicate
    entry = IERS::PolarMotion::Entry.new(
      x: 0.143,
      y: 0.137,
      mjd: 41684.0,
      data_quality: :predicted
    )

    assert_predicate entry, :predicted?
  end

  def test_is_frozen
    entry = IERS::PolarMotion::Entry.new(
      x: 0.143,
      y: 0.137,
      mjd: 41684.0,
      data_quality: :observed
    )

    assert_predicate entry, :frozen?
  end
end

class TestPolarMotionAt < Minitest::Test
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
    result = IERS::PolarMotion.at(mjd: 41687.5)

    assert_instance_of IERS::PolarMotion::Entry, result
  end

  def test_entry_x_is_float
    result = IERS::PolarMotion.at(mjd: 41687.5)

    assert_instance_of Float, result.x
  end

  def test_entry_y_is_float
    result = IERS::PolarMotion.at(mjd: 41687.5)

    assert_instance_of Float, result.y
  end

  def test_entry_has_query_mjd
    result = IERS::PolarMotion.at(mjd: 41687.5)

    assert_in_delta 41687.5, result.mjd
  end

  def test_on_exact_grid_point_prefers_bulletin_b_x
    result = IERS::PolarMotion.at(mjd: 41684.0)

    assert_in_delta 0.143, result.x, 1e-4
  end

  def test_on_exact_grid_point_prefers_bulletin_b_y
    result = IERS::PolarMotion.at(mjd: 41684.0)

    assert_in_delta 0.137, result.y, 1e-4
  end

  def test_between_grid_points_x
    result = IERS::PolarMotion.at(mjd: 41687.5)

    assert_in_delta 0.136, result.x, 1e-3
  end

  def test_between_grid_points_y
    result = IERS::PolarMotion.at(mjd: 41687.5)

    assert_in_delta 0.1265, result.y, 1e-3
  end

  def test_with_time_object
    result = IERS::PolarMotion.at(Time.utc(1973, 1, 5))

    assert_in_delta 0.137, result.x, 1e-3
  end

  def test_with_date_object
    result = IERS::PolarMotion.at(Date.new(1973, 1, 5))

    assert_in_delta 0.128, result.y, 1e-3
  end

  def test_before_data_raises_out_of_range_error
    error = assert_raises(IERS::OutOfRangeError) do
      IERS::PolarMotion.at(mjd: 41683.0)
    end

    assert_in_delta 41683.0, error.requested_mjd
    assert_equal 41684.0..41693.0, error.available_range
  end

  def test_after_data_raises_out_of_range_error
    assert_raises(IERS::OutOfRangeError) do
      IERS::PolarMotion.at(mjd: 41694.0)
    end
  end
end

class TestPolarMotionDataQuality < Minitest::Test
  def setup
    IERS.configure do |config|
      config.finals_path = fixture_path("finals_mixed_ip.dat")
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
    result = IERS::PolarMotion.at(mjd: 41685.5)

    assert_predicate result, :observed?
  end

  def test_predicted_data_is_predicted
    result = IERS::PolarMotion.at(mjd: 41688.5)

    assert_predicate result, :predicted?
  end

  def test_crossing_boundary_is_predicted
    result = IERS::PolarMotion.at(mjd: 41687.5)

    assert_predicate result, :predicted?
  end

  def test_observed_uses_bulletin_b_x
    result = IERS::PolarMotion.at(mjd: 41684.0)

    assert_in_delta 0.143, result.x, 1e-4
  end

  def test_predicted_falls_back_to_series_a
    result = IERS::PolarMotion.at(mjd: 41688.0)

    assert_in_delta 0.113721, result.x, 1e-4
  end
end
