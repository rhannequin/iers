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
