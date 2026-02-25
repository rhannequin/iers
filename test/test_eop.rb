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
