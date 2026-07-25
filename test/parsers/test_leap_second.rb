# frozen_string_literal: true

require "test_helper"

class TestLeapSecondParser < Minitest::Test
  def fixture_path(name)
    Pathname(__dir__).join("..", "fixtures", name)
  end

  def parse(name)
    IERS::Parsers::LeapSecond.parse(fixture_path(name))
  end

  def entries(name)
    parse(name).entries
  end

  def metadata(name)
    parse(name).metadata
  end

  def test_parse_returns_a_table
    assert_instance_of IERS::Parsers::LeapSecond::Table,
      parse("leap_second_sample.dat")
  end

  def test_parses_correct_number_of_entries
    assert_equal 5, entries("leap_second_sample.dat").size
  end

  def test_first_entry_mjd
    assert_in_delta 41317.0, entries("leap_second_sample.dat").first.mjd
  end

  def test_first_entry_date
    assert_equal Date.new(1972, 1, 1),
      entries("leap_second_sample.dat").first.date
  end

  def test_first_entry_tai_utc
    assert_equal 10, entries("leap_second_sample.dat").first.tai_utc
  end

  def test_last_entry_tai_utc
    assert_equal 14, entries("leap_second_sample.dat").last.tai_utc
  end

  def test_last_entry_date
    assert_equal Date.new(1975, 1, 1),
      entries("leap_second_sample.dat").last.date
  end

  def test_mjd_is_float
    assert_instance_of Float, entries("leap_second_sample.dat").first.mjd
  end

  def test_tai_utc_is_integer
    assert_instance_of Integer,
      entries("leap_second_sample.dat").first.tai_utc
  end

  def test_entry_is_a_data_object
    assert_kind_of Data, entries("leap_second_sample.dat").first
  end

  def test_entries_are_frozen
    assert_predicate entries("leap_second_sample.dat").first, :frozen?
  end

  def test_result_array_is_frozen
    assert_predicate entries("leap_second_sample.dat"), :frozen?
  end

  def test_table_is_frozen
    assert_predicate parse("leap_second_sample.dat"), :frozen?
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
      parse("leap_second_malformed.dat")
    end
  end

  def test_parse_error_includes_line_number
    error = assert_raises(IERS::ParseError) do
      parse("leap_second_malformed.dat")
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

  def test_metadata_is_a_metadata_object
    assert_instance_of IERS::Parsers::LeapSecond::Metadata,
      metadata("leap_second_with_metadata.dat")
  end

  def test_reads_expiry_date_from_header
    assert_equal Date.new(2026, 12, 28),
      metadata("leap_second_with_metadata.dat").expires_on
  end

  def test_reads_updated_through_from_header
    assert_equal "IERS Bulletin 71 issued in January 2026",
      metadata("leap_second_with_metadata.dat").updated_through
  end

  # Asserts the shape rather than the date, which moves whenever the bundled
  # snapshot is refreshed.
  def test_reads_an_expiry_from_the_bundled_file
    table = IERS::Parsers::LeapSecond.parse(
      IERS::Data::BUNDLED_DIR.join("Leap_Second.dat")
    )

    assert_instance_of Date, table.metadata.expires_on
  end

  def test_reads_an_updated_through_from_the_bundled_file
    table = IERS::Parsers::LeapSecond.parse(
      IERS::Data::BUNDLED_DIR.join("Leap_Second.dat")
    )

    assert_match(/Bulletin/, table.metadata.updated_through)
  end

  def test_expiry_is_nil_without_a_header
    assert_nil metadata("leap_second_no_metadata.dat").expires_on
  end

  def test_updated_through_is_nil_without_a_header
    assert_nil metadata("leap_second_no_metadata.dat").updated_through
  end

  def test_parses_entries_without_a_header
    assert_equal 5, entries("leap_second_no_metadata.dat").size
  end

  def test_impossible_expiry_date_is_nil
    assert_nil metadata("leap_second_bad_metadata.dat").expires_on
  end

  def test_unknown_month_name_is_nil
    assert_nil metadata("leap_second_unknown_month.dat").expires_on
  end

  def test_reworded_updated_through_line_is_nil
    assert_nil metadata("leap_second_bad_metadata.dat").updated_through
  end

  def test_unreadable_metadata_does_not_prevent_parsing_entries
    assert_equal 2, entries("leap_second_bad_metadata.dat").size
  end

  def test_invalid_encoding_in_header_does_not_raise
    assert_equal Date.new(2026, 12, 28),
      metadata("leap_second_invalid_encoding.dat").expires_on
  end

  def test_invalid_encoding_in_header_does_not_prevent_parsing_entries
    assert_equal 2, entries("leap_second_invalid_encoding.dat").size
  end
end
