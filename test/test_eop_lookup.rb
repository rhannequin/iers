# frozen_string_literal: true

require "test_helper"

class TestEopLookupWindow < Minitest::Test
  def setup
    @entries = IERS::Parsers::Finals.parse(fixture_path("finals_10_days.dat"))
  end

  def fixture_path(name)
    Pathname(__dir__).join("fixtures", name)
  end

  def test_returns_4_entries_by_default
    window = IERS::EopLookup.window(@entries, 41687.5)

    assert_equal 4, window.size
  end

  def test_centers_around_query_mjd
    window = IERS::EopLookup.window(@entries, 41687.5)
    mjds = window.map(&:mjd)

    assert_equal [41686.0, 41687.0, 41688.0, 41689.0], mjds
  end

  def test_shifts_right_at_left_boundary
    window = IERS::EopLookup.window(@entries, 41684.5)
    mjds = window.map(&:mjd)

    assert_equal [41684.0, 41685.0, 41686.0, 41687.0], mjds
  end

  def test_shifts_left_at_right_boundary
    window = IERS::EopLookup.window(@entries, 41692.5)
    mjds = window.map(&:mjd)

    assert_equal [41690.0, 41691.0, 41692.0, 41693.0], mjds
  end

  def test_on_exact_last_entry_mjd
    window = IERS::EopLookup.window(@entries, 41693.0)
    mjds = window.map(&:mjd)

    assert_equal [41690.0, 41691.0, 41692.0, 41693.0], mjds
  end

  def test_custom_order_6
    window = IERS::EopLookup.window(@entries, 41688.5, order: 6)

    assert_equal 6, window.size
  end

  def test_order_2_returns_two_entries
    window = IERS::EopLookup.window(@entries, 41687.5, order: 2)

    assert_equal 2, window.size
    assert_equal [41687.0, 41688.0], window.map(&:mjd)
  end

  def test_returns_parser_entry_objects
    window = IERS::EopLookup.window(@entries, 41687.5)

    assert_instance_of IERS::Parsers::Finals::Entry, window.first
  end

  def test_before_data_raises_out_of_range_error
    assert_raises(IERS::OutOfRangeError) do
      IERS::EopLookup.window(@entries, 41683.0)
    end
  end

  def test_before_data_error_has_attributes
    error = assert_raises(IERS::OutOfRangeError) do
      IERS::EopLookup.window(@entries, 41683.0)
    end

    assert_in_delta 41683.0, error.requested_mjd
    assert_equal 41684.0..41693.0, error.available_range
  end

  def test_after_data_raises_out_of_range_error
    assert_raises(IERS::OutOfRangeError) do
      IERS::EopLookup.window(@entries, 41694.0)
    end
  end
end

class TestEopLookupBracket < Minitest::Test
  def setup
    @entries = IERS::Parsers::Finals.parse(fixture_path("finals_10_days.dat"))
  end

  def fixture_path(name)
    Pathname(__dir__).join("fixtures", name)
  end

  def test_returns_2_entries
    bracket = IERS::EopLookup.bracket(@entries, 41687.5)

    assert_equal 2, bracket.size
  end

  def test_surrounds_query_mjd
    bracket = IERS::EopLookup.bracket(@entries, 41687.5)
    mjds = bracket.map(&:mjd)

    assert_equal [41687.0, 41688.0], mjds
  end

  def test_on_exact_mjd_returns_entry_and_next
    bracket = IERS::EopLookup.bracket(@entries, 41687.0)
    mjds = bracket.map(&:mjd)

    assert_equal [41687.0, 41688.0], mjds
  end

  def test_on_last_entry_raises_out_of_range_error
    assert_raises(IERS::OutOfRangeError) do
      IERS::EopLookup.bracket(@entries, 41693.0)
    end
  end
end
