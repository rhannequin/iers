# frozen_string_literal: true

require "test_helper"

class TestC04Parser < Minitest::Test
  def fixture_path(name)
    Pathname(__dir__).join("..", "fixtures", name)
  end

  def entries
    IERS::Parsers::C04.parse(fixture_path("c04_sample.dat"))
  end

  def test_skips_header_lines
    assert_equal 3, entries.size
  end

  def test_first_entry_date
    assert_equal Date.new(1973, 1, 2), entries.first.date
  end

  def test_first_entry_mjd
    assert_in_delta 41684.0, entries.first.mjd
  end

  def test_first_entry_pm_x
    assert_in_delta 0.1235, entries.first.pm_x
  end

  def test_first_entry_pm_y
    assert_in_delta 0.123, entries.first.pm_y
  end

  def test_first_entry_ut1_utc
    assert_in_delta 0.8078584, entries.first.ut1_utc
  end

  def test_first_entry_celestial_pole_offsets
    entry = entries.first

    assert_in_delta 0.0, entry.dx
    assert_in_delta 0.0, entry.dy
  end

  def test_first_entry_lod
    assert_in_delta 0.00271, entries.first.lod
  end

  def test_first_entry_errors
    entry = entries.first

    assert_in_delta 0.015, entry.pm_x_error
    assert_in_delta 0.015, entry.pm_y_error
    assert_in_delta 0.0019, entry.ut1_utc_error
    assert_in_delta 0.001989, entry.dx_error
    assert_in_delta 0.002, entry.dy_error
    assert_in_delta 0.0007, entry.lod_error
  end

  def test_last_entry_date
    assert_equal Date.new(1973, 1, 4), entries.last.date
  end

  def test_entries_are_frozen
    assert_predicate entries, :frozen?
  end

  def test_missing_file_raises_file_not_found
    error = assert_raises(IERS::FileNotFoundError) do
      IERS::Parsers::C04.parse(fixture_path("nonexistent.dat"))
    end

    assert_match(/nonexistent\.dat/, error.path)
  end

  def test_short_line_raises_parse_error_with_line_number
    error = assert_raises(IERS::ParseError) do
      IERS::Parsers::C04.parse(fixture_path("c04_malformed.dat"))
    end

    assert_equal 8, error.line_number
  end

  def test_non_numeric_field_raises_parse_error
    Tempfile.create(["c04", ".dat"]) do |file|
      file.write(
        "# YR  MM  DD  HH       MJD        x(\")        y(\")  UT1-UTC(s)" \
        "       dX(\")       dY(\")\n" \
        "1973   1   2   0  41684.00    abc    0.123000   0.8078584" \
        "    0.0 0.0 0.0 0.0 0.0027100 0.015 0.015 0.0019 0.001989" \
        " 0.002 0.0 0.0 0.0007\n"
      )
      file.flush

      error = assert_raises(IERS::ParseError) do
        IERS::Parsers::C04.parse(file.path)
      end

      assert_equal 2, error.line_number
    end
  end

  def test_invalid_date_raises_parse_error
    Tempfile.create(["c04", ".dat"]) do |file|
      file.write(
        "# YR  MM  DD  HH       MJD        x(\")        y(\")  UT1-UTC(s)" \
        "       dX(\")       dY(\")\n" \
        "1973  13   2   0  41684.00    0.1235    0.123000   0.8078584" \
        "    0.0 0.0 0.0 0.0 0.0027100 0.015 0.015 0.0019 0.001989" \
        " 0.002 0.0 0.0 0.0007\n"
      )
      file.flush

      assert_raises(IERS::ParseError) do
        IERS::Parsers::C04.parse(file.path)
      end
    end
  end

  def test_invalid_utf8_is_tolerated
    Tempfile.create(["c04", ".dat"]) do |file|
      file.binmode
      file.write("# Observatoire \xE9 \xFF\n")
      file.write(fixture_path("c04_sample.dat").binread)
      file.flush

      assert_equal 3, IERS::Parsers::C04.parse(file.path).size
    end
  end

  def test_dpsi_deps_variant_raises_parse_error
    Tempfile.create(["c04", ".dat"]) do |file|
      file.write(
        fixture_path("c04_sample.dat").read
          .sub("dX(\")", "dPsi(\")").sub("dY(\")", "dEps(\")")
      )
      file.flush

      error = assert_raises(IERS::ParseError) do
        IERS::Parsers::C04.parse(file.path)
      end

      assert_match(/dX/, error.message)
    end
  end

  def test_12h_variant_raises_parse_error
    Tempfile.create(["c04", ".dat"]) do |file|
      file.write(
        fixture_path("c04_sample.dat").read
          .sub("1973   1   2   0  41684.00", "1973   1   2  12  41684.50")
      )
      file.flush

      assert_raises(IERS::ParseError) do
        IERS::Parsers::C04.parse(file.path)
      end
    end
  end

  def test_data_before_column_header_raises_parse_error
    Tempfile.create(["c04", ".dat"]) do |file|
      data_lines = fixture_path("c04_sample.dat").read.lines
        .reject { |line| line.start_with?("#") }
      file.write(data_lines.join)
      file.flush

      assert_raises(IERS::ParseError) do
        IERS::Parsers::C04.parse(file.path)
      end
    end
  end
end
