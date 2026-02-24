# frozen_string_literal: true

require "test_helper"

class TestLeapSecondParser < Minitest::Test
  def fixture_path(name)
    Pathname(__dir__).join("..", "fixtures", name)
  end

  def test_parses_correct_number_of_entries
    entries = IERS::Parsers::LeapSecond
      .parse(fixture_path("leap_second_sample.dat"))

    assert_equal 5, entries.size
  end

  def test_first_entry_mjd
    entries = IERS::Parsers::LeapSecond
      .parse(fixture_path("leap_second_sample.dat"))

    assert_in_delta 41317.0, entries.first.mjd
  end

  def test_first_entry_date
    entries = IERS::Parsers::LeapSecond
      .parse(fixture_path("leap_second_sample.dat"))

    assert_equal Date.new(1972, 1, 1), entries.first.date
  end

  def test_first_entry_tai_utc
    entries = IERS::Parsers::LeapSecond
      .parse(fixture_path("leap_second_sample.dat"))

    assert_equal 10, entries.first.tai_utc
  end

  def test_last_entry_tai_utc
    entries = IERS::Parsers::LeapSecond
      .parse(fixture_path("leap_second_sample.dat"))

    assert_equal 14, entries.last.tai_utc
  end

  def test_last_entry_date
    entries = IERS::Parsers::LeapSecond
      .parse(fixture_path("leap_second_sample.dat"))

    assert_equal Date.new(1975, 1, 1), entries.last.date
  end

  def test_mjd_is_float
    entries = IERS::Parsers::LeapSecond
      .parse(fixture_path("leap_second_sample.dat"))

    assert_instance_of Float, entries.first.mjd
  end

  def test_tai_utc_is_integer
    entries = IERS::Parsers::LeapSecond
      .parse(fixture_path("leap_second_sample.dat"))

    assert_instance_of Integer, entries.first.tai_utc
  end

  def test_entry_is_a_data_object
    entries = IERS::Parsers::LeapSecond
      .parse(fixture_path("leap_second_sample.dat"))

    assert_kind_of Data, entries.first
  end

  def test_entries_are_frozen
    entries = IERS::Parsers::LeapSecond
      .parse(fixture_path("leap_second_sample.dat"))

    assert_predicate entries.first, :frozen?
  end

  def test_result_array_is_frozen
    entries = IERS::Parsers::LeapSecond
      .parse(fixture_path("leap_second_sample.dat"))

    assert_predicate entries, :frozen?
  end

  def test_raises_file_not_found_error_for_missing_file
    assert_raises(IERS::FileNotFoundError) do
      IERS::Parsers::LeapSecond.parse(Pathname("/nonexistent/path/file.dat"))
    end
  end

  def test_file_not_found_error_includes_path
    error = assert_raises(IERS::FileNotFoundError) do
      IERS::Parsers::LeapSecond.parse(Pathname("/nonexistent/path/file.dat"))
    end

    assert_equal "/nonexistent/path/file.dat", error.path
  end

  def test_raises_parse_error_for_malformed_data
    assert_raises(IERS::ParseError) do
      IERS::Parsers::LeapSecond.parse(fixture_path("leap_second_malformed.dat"))
    end
  end

  def test_parse_error_includes_line_number
    error = assert_raises(IERS::ParseError) do
      IERS::Parsers::LeapSecond.parse(fixture_path("leap_second_malformed.dat"))
    end

    assert_equal 6, error.line_number
  end

  def test_parse_error_includes_path
    path = fixture_path("leap_second_malformed.dat")

    error = assert_raises(IERS::ParseError) do
      IERS::Parsers::LeapSecond.parse(path)
    end

    assert_equal path.to_s, error.path
  end
end
