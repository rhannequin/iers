# frozen_string_literal: true

require "test_helper"

class TestFinalsParser < Minitest::Test
  def fixture_path(name)
    Pathname(__dir__).join("..", "fixtures", name)
  end

  # happy path: core fields

  def test_parses_correct_number_of_entries
    entries = IERS::Parsers::Finals
      .parse(fixture_path("finals_sample.dat"))

    assert_equal 3, entries.size
  end

  def test_first_entry_date
    entries = IERS::Parsers::Finals
      .parse(fixture_path("finals_sample.dat"))

    assert_equal Date.new(1973, 1, 2), entries.first.date
  end

  def test_first_entry_mjd
    entries = IERS::Parsers::Finals
      .parse(fixture_path("finals_sample.dat"))

    assert_in_delta 41684.0, entries.first.mjd
  end

  def test_first_entry_pm_flag
    entries = IERS::Parsers::Finals
      .parse(fixture_path("finals_sample.dat"))

    assert_equal "I", entries.first.pm_flag
  end

  def test_first_entry_pm_x
    entries = IERS::Parsers::Finals
      .parse(fixture_path("finals_sample.dat"))

    assert_in_delta 0.120733, entries.first.pm_x
  end

  def test_first_entry_pm_x_error
    entries = IERS::Parsers::Finals
      .parse(fixture_path("finals_sample.dat"))

    assert_in_delta 0.009786, entries.first.pm_x_error
  end

  def test_first_entry_pm_y
    entries = IERS::Parsers::Finals
      .parse(fixture_path("finals_sample.dat"))

    assert_in_delta 0.136966, entries.first.pm_y
  end

  def test_first_entry_pm_y_error
    entries = IERS::Parsers::Finals
      .parse(fixture_path("finals_sample.dat"))

    assert_in_delta 0.015902, entries.first.pm_y_error
  end

  def test_first_entry_ut1_flag
    entries = IERS::Parsers::Finals
      .parse(fixture_path("finals_sample.dat"))

    assert_equal "I", entries.first.ut1_flag
  end

  def test_first_entry_ut1_utc
    entries = IERS::Parsers::Finals
      .parse(fixture_path("finals_sample.dat"))

    assert_in_delta 0.8084178, entries.first.ut1_utc
  end

  def test_first_entry_ut1_utc_error
    entries = IERS::Parsers::Finals
      .parse(fixture_path("finals_sample.dat"))

    assert_in_delta 0.0002710, entries.first.ut1_utc_error
  end

  def test_first_entry_lod
    entries = IERS::Parsers::Finals
      .parse(fixture_path("finals_sample.dat"))

    assert_in_delta 0.0, entries.first.lod
  end

  def test_first_entry_lod_error
    entries = IERS::Parsers::Finals
      .parse(fixture_path("finals_sample.dat"))

    assert_in_delta 0.1916, entries.first.lod_error
  end

  def test_first_entry_nutation_flag
    entries = IERS::Parsers::Finals
      .parse(fixture_path("finals_sample.dat"))

    assert_equal "P", entries.first.nutation_flag
  end

  def test_first_entry_dx
    entries = IERS::Parsers::Finals
      .parse(fixture_path("finals_sample.dat"))

    assert_in_delta(-0.766, entries.first.dx)
  end

  def test_first_entry_dx_error
    entries = IERS::Parsers::Finals
      .parse(fixture_path("finals_sample.dat"))

    assert_in_delta 0.199, entries.first.dx_error
  end

  def test_first_entry_dy
    entries = IERS::Parsers::Finals
      .parse(fixture_path("finals_sample.dat"))

    assert_in_delta(-0.720, entries.first.dy)
  end

  def test_first_entry_dy_error
    entries = IERS::Parsers::Finals
      .parse(fixture_path("finals_sample.dat"))

    assert_in_delta 0.300, entries.first.dy_error
  end

  # Bulletin B fields

  def test_first_entry_bulletin_b_pm_x
    entries = IERS::Parsers::Finals
      .parse(fixture_path("finals_sample.dat"))

    assert_in_delta 0.143, entries.first.bulletin_b_pm_x
  end

  def test_first_entry_bulletin_b_pm_y
    entries = IERS::Parsers::Finals
      .parse(fixture_path("finals_sample.dat"))

    assert_in_delta 0.137, entries.first.bulletin_b_pm_y
  end

  def test_first_entry_bulletin_b_ut1_utc
    entries = IERS::Parsers::Finals
      .parse(fixture_path("finals_sample.dat"))

    assert_in_delta 0.8075, entries.first.bulletin_b_ut1_utc
  end

  def test_first_entry_bulletin_b_dx
    entries = IERS::Parsers::Finals
      .parse(fixture_path("finals_sample.dat"))

    assert_in_delta(-18.637, entries.first.bulletin_b_dx)
  end

  def test_first_entry_bulletin_b_dy
    entries = IERS::Parsers::Finals
      .parse(fixture_path("finals_sample.dat"))

    assert_in_delta(-3.667, entries.first.bulletin_b_dy)
  end

  # predicted data with blank optional fields

  def test_predicted_entry_pm_flag
    entries = IERS::Parsers::Finals
      .parse(fixture_path("finals_predicted.dat"))

    assert_equal "P", entries.first.pm_flag
  end

  def test_predicted_entry_ut1_flag
    entries = IERS::Parsers::Finals
      .parse(fixture_path("finals_predicted.dat"))

    assert_equal "P", entries.first.ut1_flag
  end

  def test_predicted_entry_lod_is_nil_when_blank
    entries = IERS::Parsers::Finals
      .parse(fixture_path("finals_predicted.dat"))

    assert_nil entries.first.lod
  end

  def test_predicted_entry_lod_error_is_nil_when_blank
    entries = IERS::Parsers::Finals
      .parse(fixture_path("finals_predicted.dat"))

    assert_nil entries.first.lod_error
  end

  def test_predicted_entry_bulletin_b_pm_x_is_nil
    entries = IERS::Parsers::Finals
      .parse(fixture_path("finals_predicted.dat"))

    assert_nil entries.first.bulletin_b_pm_x
  end

  def test_predicted_entry_bulletin_b_pm_y_is_nil
    entries = IERS::Parsers::Finals
      .parse(fixture_path("finals_predicted.dat"))

    assert_nil entries.first.bulletin_b_pm_y
  end

  def test_predicted_entry_bulletin_b_ut1_utc_is_nil
    entries = IERS::Parsers::Finals
      .parse(fixture_path("finals_predicted.dat"))

    assert_nil entries.first.bulletin_b_ut1_utc
  end

  def test_predicted_entry_bulletin_b_dx_is_nil
    entries = IERS::Parsers::Finals
      .parse(fixture_path("finals_predicted.dat"))

    assert_nil entries.first.bulletin_b_dx
  end

  def test_predicted_entry_bulletin_b_dy_is_nil
    entries = IERS::Parsers::Finals
      .parse(fixture_path("finals_predicted.dat"))

    assert_nil entries.first.bulletin_b_dy
  end

  # Y2K year pivot

  def test_year_99_with_low_mjd_resolves_to_1999
    entries = IERS::Parsers::Finals
      .parse(fixture_path("finals_y2k_boundary.dat"))

    assert_equal Date.new(1999, 1, 1), entries.first.date
  end

  def test_year_00_with_high_mjd_resolves_to_2000
    entries = IERS::Parsers::Finals
      .parse(fixture_path("finals_y2k_boundary.dat"))

    assert_equal Date.new(2000, 1, 1), entries.last.date
  end

  # error handling

  def test_raises_file_not_found_error_for_missing_file
    assert_raises(IERS::FileNotFoundError) do
      IERS::Parsers::Finals.parse(Pathname("/nonexistent/path/file.dat"))
    end
  end

  def test_file_not_found_error_includes_path
    error = assert_raises(IERS::FileNotFoundError) do
      IERS::Parsers::Finals.parse(Pathname("/nonexistent/path/file.dat"))
    end

    assert_equal "/nonexistent/path/file.dat", error.path
  end

  def test_raises_parse_error_for_malformed_data
    assert_raises(IERS::ParseError) do
      IERS::Parsers::Finals.parse(fixture_path("finals_malformed.dat"))
    end
  end

  def test_parse_error_includes_line_number
    error = assert_raises(IERS::ParseError) do
      IERS::Parsers::Finals.parse(fixture_path("finals_malformed.dat"))
    end

    assert_equal 2, error.line_number
  end

  def test_parse_error_includes_path
    path = fixture_path("finals_malformed.dat")

    error = assert_raises(IERS::ParseError) do
      IERS::Parsers::Finals.parse(path)
    end

    assert_equal path.to_s, error.path
  end

  # immutability and types

  def test_entry_is_a_data_object
    entries = IERS::Parsers::Finals
      .parse(fixture_path("finals_sample.dat"))

    assert_kind_of Data, entries.first
  end

  def test_entries_are_frozen
    entries = IERS::Parsers::Finals
      .parse(fixture_path("finals_sample.dat"))

    assert_predicate entries.first, :frozen?
  end

  def test_result_array_is_frozen
    entries = IERS::Parsers::Finals
      .parse(fixture_path("finals_sample.dat"))

    assert_predicate entries, :frozen?
  end

  def test_mjd_is_float
    entries = IERS::Parsers::Finals
      .parse(fixture_path("finals_sample.dat"))

    assert_instance_of Float, entries.first.mjd
  end

  def test_date_is_date
    entries = IERS::Parsers::Finals
      .parse(fixture_path("finals_sample.dat"))

    assert_instance_of Date, entries.first.date
  end

  def test_skips_blank_lines
    entries = IERS::Parsers::Finals
      .parse(fixture_path("finals_sample.dat"))

    refute_predicate entries, :empty?
  end
end
