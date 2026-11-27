# frozen_string_literal: true

require "test_helper"

class TestC04Overlay < Minitest::Test
  def setup
    IERS.configure do |config|
      config.finals_path = fixture_path("finals_c04_overlay.dat")
      config.c04_path = fixture_path("c04_overlay.dat")
      config.leap_second_path = fixture_path("leap_second_query.dat")
    end
  end

  def teardown
    IERS.reset_configuration!
  end

  def test_rows_covered_by_c04_take_its_pole_coordinates
    entry = IERS::Data.eop_entries.first

    assert_in_delta(-0.133010, entry.pm_x)
    assert_in_delta 0.091197, entry.pm_y
    assert_in_delta 0.001250, entry.pm_x_error
  end

  def test_rows_covered_by_c04_take_its_ut1
    assert_in_delta 0.3975740, IERS::Data.eop_entries.first.ut1_utc
  end

  def test_c04_lod_is_converted_to_milliseconds
    entry = IERS::Data.eop_entries.first

    assert_in_delta 1.4850, entry.lod
    assert_in_delta 0.0730, entry.lod_error
  end

  def test_c04_celestial_pole_offsets_are_converted_to_milliarcseconds
    entry = IERS::Data.eop_entries.first

    assert_in_delta 2.718, entry.dx
    assert_in_delta(-3.287, entry.dy)
    assert_in_delta 0.349, entry.dx_error
  end

  def test_rows_covered_by_c04_drop_bulletin_b_values
    entry = IERS::Data.eop_entries.first

    assert_nil entry.bulletin_b_pm_x
    assert_nil entry.bulletin_b_pm_y
    assert_nil entry.bulletin_b_ut1_utc
  end

  def test_rows_covered_by_c04_are_observed
    entry = IERS::Data.eop_entries.first

    assert_equal "I", entry.pm_flag
    assert_equal "I", entry.ut1_flag
    assert_equal "I", entry.nutation_flag
  end

  def test_rows_after_c04_are_finals_as_is
    finals = IERS::Data.finals_entries.last

    assert_equal finals, IERS::Data.eop_entries.last
  end

  def test_keeps_every_finals_row
    assert_equal IERS::Data.finals_entries.map(&:mjd),
      IERS::Data.eop_entries.map(&:mjd)
  end

  def test_queries_read_c04_values
    pm = IERS::PolarMotion.at(mjd: 45701.0)

    assert_in_delta(-0.135118, pm.x, 1e-9)
  end

  def test_finals_source_skips_c04
    IERS.configuration.eop_source = :finals

    assert_equal IERS::Data.finals_entries, IERS::Data.eop_entries
  end

  def test_switching_source_takes_effect_on_next_query
    IERS::Data.eop_entries
    IERS.configuration.eop_source = :finals

    bulletin_b = IERS::Data.finals_entries[1].bulletin_b_pm_x

    assert_in_delta bulletin_b, IERS::PolarMotion.at(mjd: 45701.0).x, 1e-9
  end

  def test_clearing_c04_reloads_it
    Dir.mktmpdir do |dir|
      path = Pathname(dir).join("eopc04")
      FileUtils.cp(fixture_path("c04_overlay.dat"), path)
      IERS.configuration.c04_path = path
      IERS::Data.eop_entries

      path.write(path.read.sub("-0.133010", "-0.200000"))
      IERS::Data.clear_loaded!(:c04)

      assert_in_delta(-0.2, IERS::Data.eop_entries.first.pm_x)
    end
  end

  def test_unreadable_c04_falls_back_to_bundled_c04_quietly
    IERS.configuration.c04_path = fixture_path("c04_malformed.dat")
    bundled = IERS::Parsers::C04.parse(
      IERS::Data::BUNDLED_DIR.join("eopc04.1962-now")
    ).find { |e| e.date == Date.new(1984, 1, 1) }

    entries = nil

    assert_silent { entries = IERS::Data.eop_entries }
    assert_in_delta bundled.pm_x, entries.first.pm_x
  end

  def test_c04_path_to_a_directory_falls_back_quietly
    Dir.mktmpdir do |dir|
      IERS.configuration.c04_path = dir

      assert_silent { IERS::Data.eop_entries }
    end
  end

  def test_no_readable_c04_falls_back_to_finals
    IERS.configuration.c04_path = fixture_path("c04_malformed.dat")

    with_bundled_dir(fixture_path("missing")) do
      assert_equal IERS::Data.finals_entries, IERS::Data.eop_entries
    end
  end

  def test_unreadable_c04_still_raises_when_read_directly
    IERS.configuration.c04_path = fixture_path("c04_malformed.dat")

    assert_raises(IERS::ParseError) { IERS::Data.c04_entries }
  end

  private

  def fixture_path(name)
    Pathname(__dir__).join("fixtures", name)
  end

  def with_bundled_dir(dir)
    original = IERS::Data::BUNDLED_DIR
    IERS::Data.send(:remove_const, :BUNDLED_DIR)
    IERS::Data.const_set(:BUNDLED_DIR, dir)
    yield
  ensure
    IERS::Data.send(:remove_const, :BUNDLED_DIR)
    IERS::Data.const_set(:BUNDLED_DIR, original)
  end
end

class TestC04OverlayWithPredictedFinals < Minitest::Test
  def setup
    IERS.configure do |config|
      config.finals_path = fixture_path("finals_c04_seam.dat")
      config.c04_path = fixture_path("c04_overlay.dat")
      config.leap_second_path = fixture_path("leap_second_query.dat")
    end
  end

  def teardown
    IERS.reset_configuration!
  end

  def test_predicted_finals_rows_are_not_overlaid
    finals = IERS::Data.finals_entries[2]

    assert_equal finals, IERS::Data.eop_entries[2]
  end

  def test_observed_finals_rows_are_overlaid
    assert_in_delta(-0.135118, IERS::Data.eop_entries[1].pm_x)
  end

  def test_between_reads_c04_then_finals
    xs = IERS::PolarMotion
      .between(Date.new(1984, 1, 1), Date.new(1984, 1, 4))
      .map(&:x).to_a
    finals = IERS::Data.finals_entries

    assert_in_delta(-0.133010, xs[0])
    assert_in_delta(-0.135118, xs[1])
    assert_in_delta finals[2].bulletin_b_pm_x || finals[2].pm_x, xs[2]
  end

  def test_between_reports_quality_per_row
    qualities = IERS::EOP
      .between(Date.new(1984, 1, 1), Date.new(1984, 1, 4))
      .map(&:data_quality).to_a

    assert_equal %i[observed observed predicted predicted], qualities
  end

  def test_window_reaching_predicted_rows_is_predicted
    assert_predicate IERS::UT1.at(mjd: 45701.5), :predicted?
  end

  def test_linear_bracket_within_c04_is_observed
    ut1 = IERS::UT1.at(mjd: 45700.5, interpolation: :linear)

    assert_predicate ut1, :observed?
  end

  private

  def fixture_path(name)
    Pathname(__dir__).join("fixtures", name)
  end
end

class TestC04OverlayMalformedFinals < Minitest::Test
  def setup
    IERS.configure do |config|
      config.finals_path = Pathname(__dir__).join(
        "fixtures", "finals_malformed.dat"
      )
    end
  end

  def teardown
    IERS.reset_configuration!
  end

  def test_malformed_finals_still_raises
    assert_raises(IERS::ParseError) { IERS::UT1.at(mjd: 41684.0) }
  end
end

class TestC04OverlayBeforeCelestialPoleData < Minitest::Test
  def setup
    IERS.configure do |config|
      config.finals_path = fixture_path("finals_sample.dat")
      config.c04_path = fixture_path("c04_sample.dat")
    end
  end

  def teardown
    IERS.reset_configuration!
  end

  def test_keeps_finals_celestial_pole_offsets_before_1984
    entry = IERS::Data.eop_entries.first

    assert_in_delta(-0.766, entry.dx)
    assert_in_delta(-0.720, entry.dy)
    assert_equal "P", entry.nutation_flag
  end

  def test_still_takes_c04_pole_coordinates_before_1984
    assert_in_delta 0.1235, IERS::Data.eop_entries.first.pm_x
  end

  private

  def fixture_path(name)
    Pathname(__dir__).join("fixtures", name)
  end
end

class TestC04BundledSeam < Minitest::Test
  def setup
    @cache_dir = Dir.mktmpdir("iers-test")
    IERS.configure { |config| config.cache_dir = @cache_dir }
  end

  def teardown
    FileUtils.remove_entry(@cache_dir)
    IERS.reset_configuration!
  end

  def test_c04_and_finals_agree_where_c04_ends
    c04 = IERS::Data.c04_entries.last
    finals = IERS::Data.finals_entries.find { |e| e.mjd == c04.mjd }

    assert_in_delta c04.pm_x, finals.pm_x, 0.0005
    assert_in_delta c04.pm_y, finals.pm_y, 0.0005
    assert_in_delta c04.ut1_utc, finals.ut1_utc, 0.0002
  end
end
