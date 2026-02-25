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
