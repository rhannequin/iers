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
