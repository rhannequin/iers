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
    end
  end

  def teardown
    IERS.reset_configuration!
  end

  def fixture_path(name)
    Pathname(__dir__).join("fixtures", name)
  end

  def test_returns_float
    assert_instance_of Float, IERS::UT1.at(mjd: 41687.5)
  end

  def test_on_exact_grid_point
    assert_in_delta 0.8084178, IERS::UT1.at(mjd: 41684.0)
  end

  def test_between_grid_points
    result = IERS::UT1.at(mjd: 41687.5)

    assert_operator result, :>, 0.79702
    assert_operator result, :<, 0.79991
  end

  def test_with_time_object
    result = IERS::UT1.at(Time.utc(1973, 1, 5))

    assert_in_delta 0.79991, result, 1e-4
  end

  def test_with_date_object
    result = IERS::UT1.at(Date.new(1973, 1, 5))

    assert_in_delta 0.79991, result, 1e-4
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
