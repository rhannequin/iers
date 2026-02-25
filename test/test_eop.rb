# frozen_string_literal: true

require "test_helper"

class TestEOPEntry < Minitest::Test
  def build_entry(**overrides)
    defaults = {
      polar_motion_x: 0.137,
      polar_motion_y: 0.128,
      ut1_utc: 0.799,
      length_of_day: 0.0028,
      celestial_pole_x: -18.700,
      celestial_pole_y: -3.650,
      mjd: 41687.0,
      data_quality: :observed
    }
    IERS::EOP::Entry.new(**defaults.merge(overrides))
  end

  def test_has_polar_motion_x
    assert_in_delta 0.137, build_entry.polar_motion_x
  end

  def test_has_polar_motion_y
    assert_in_delta 0.128, build_entry.polar_motion_y
  end

  def test_has_ut1_utc
    assert_in_delta 0.799, build_entry.ut1_utc
  end

  def test_has_length_of_day
    assert_in_delta 0.0028, build_entry.length_of_day
  end

  def test_has_celestial_pole_x
    assert_in_delta(-18.700, build_entry.celestial_pole_x)
  end

  def test_has_celestial_pole_y
    assert_in_delta(-3.650, build_entry.celestial_pole_y)
  end

  def test_has_mjd
    assert_in_delta 41687.0, build_entry.mjd
  end

  def test_has_data_quality
    assert_equal :observed, build_entry.data_quality
  end

  def test_observed_predicate
    assert_predicate build_entry, :observed?
  end

  def test_predicted_predicate
    entry = build_entry(data_quality: :predicted)

    assert_predicate entry, :predicted?
  end

  def test_is_frozen
    assert_predicate build_entry, :frozen?
  end
end

class TestEOPAt < Minitest::Test
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

  def test_returns_entry_instance
    result = IERS::EOP.at(mjd: 41687.0)

    assert_instance_of IERS::EOP::Entry, result
  end

  def test_polar_motion_x
    result = IERS::EOP.at(mjd: 41687.0)

    assert_in_delta 0.137, result.polar_motion_x, 1e-3
  end

  def test_polar_motion_y
    result = IERS::EOP.at(mjd: 41687.0)

    assert_in_delta 0.128, result.polar_motion_y, 1e-3
  end

  def test_ut1_utc
    result = IERS::EOP.at(mjd: 41687.0)

    assert_in_delta 0.799, result.ut1_utc, 1e-3
  end

  def test_length_of_day
    result = IERS::EOP.at(mjd: 41687.0)

    assert_in_delta 0.0028, result.length_of_day, 1e-4
  end

  def test_celestial_pole_x
    result = IERS::EOP.at(mjd: 41687.0)

    assert_in_delta(-18.700, result.celestial_pole_x, 1e-3)
  end

  def test_celestial_pole_y
    result = IERS::EOP.at(mjd: 41687.0)

    assert_in_delta(-3.650, result.celestial_pole_y, 1e-3)
  end

  def test_entry_has_query_mjd
    result = IERS::EOP.at(mjd: 41687.5)

    assert_in_delta 41687.5, result.mjd
  end

  def test_with_time_object
    result = IERS::EOP.at(Time.utc(1973, 1, 5))

    assert_instance_of IERS::EOP::Entry, result
  end

  def test_with_date_object
    result = IERS::EOP.at(Date.new(1973, 1, 5))

    assert_instance_of IERS::EOP::Entry, result
  end

  def test_before_data_raises_out_of_range_error
    assert_raises(IERS::OutOfRangeError) do
      IERS::EOP.at(mjd: 41683.0)
    end
  end

  def test_after_data_raises_out_of_range_error
    assert_raises(IERS::OutOfRangeError) do
      IERS::EOP.at(mjd: 41694.0)
    end
  end
end

class TestEOPDataQuality < Minitest::Test
  def setup
    IERS.configure do |config|
      config.finals_path = fixture_path("finals_eop_mixed.dat")
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
    result = IERS::EOP.at(mjd: 41685.5)

    assert_predicate result, :observed?
  end

  def test_predicted_data_is_predicted
    result = IERS::EOP.at(mjd: 41688.5)

    assert_predicate result, :predicted?
  end

  def test_crossing_boundary_is_predicted
    result = IERS::EOP.at(mjd: 41687.5)

    assert_predicate result, :predicted?
  end
end
