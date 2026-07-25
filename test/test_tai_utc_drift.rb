# frozen_string_literal: true

require "test_helper"

class TestTaiUtcDrift < Minitest::Test
  # TAI−UTC at each segment boundary, from the USNO tai-utc.dat coefficients.
  # Cross-checked against ERFA (pyerfa 2.0.1.5): erfa.dat(y, m, d, 0.0) agrees
  # to under 1e-9 s for every value below.
  BOUNDARIES = {
    37_300 => 1.4228180, # 1961-01-01
    37_512 => 1.6475700, # 1961-08-01
    37_665 => 1.8458580, # 1962-01-01
    38_334 => 2.6972788, # 1963-11-01
    38_395 => 2.7657940, # 1964-01-01
    38_486 => 2.9837300, # 1964-04-01
    38_639 => 3.2820180, # 1964-09-01
    38_761 => 3.5401300, # 1965-01-01
    38_820 => 3.7165940, # 1965-03-01
    38_942 => 3.9747060, # 1965-07-01
    39_004 => 4.1550580, # 1965-09-01
    39_126 => 4.3131700, # 1966-01-01
    39_887 => 6.1856820, # 1968-02-01
    41_317 => 10.0000000 # 1972-01-01
  }.freeze

  # Dates inside a segment whose reference_mjd lies elsewhere, so a wrong rate
  # or reference_mjd is caught here even when the boundaries happen to match.
  # ERFA values, pyerfa 2.0.1.5.
  MID_SEGMENT = {
    38_195 => 2.4411540, # 1963-06-15
    38_900 => 3.8202740, # 1965-05-20
    39_675 => 5.7361780, # 1967-07-04
    40_646 => 8.1530100, # 1970-03-01
    37_399 => 1.5511220  # 1961-04-10
  }.freeze

  def test_every_boundary_matches_the_published_value
    BOUNDARIES.each do |mjd, expected|
      assert_in_delta expected, IERS::TaiUtcDrift.at(mjd).to_f, 1e-9,
        "MJD #{mjd}"
    end
  end

  def test_mid_segment_samples_match_erfa
    MID_SEGMENT.each do |mjd, expected|
      assert_in_delta expected, IERS::TaiUtcDrift.at(mjd).to_f, 1e-9,
        "MJD #{mjd}"
    end
  end

  # UTC was stepped down at 1961-08-01, so TAI−UTC is discontinuous there.
  def test_value_steps_down_at_1961_08_01
    before = IERS::TaiUtcDrift.at(37_511)
    on = IERS::TaiUtcDrift.at(37_512)

    assert_operator on, :<, before
  end

  def test_at_returns_a_rational
    assert_kind_of Rational, IERS::TaiUtcDrift.at(38_000)
  end

  def test_value_is_exact
    # 1962-01-01 segment: 1.8458580 + (38000 - 37665) * 0.0011232
    assert_equal Rational(18_458_580, 10_000_000) +
      (38_000 - 37_665) * Rational(11_232, 10_000_000),
      IERS::TaiUtcDrift.at(38_000)
  end

  def test_covers_is_false_below_the_first_mjd
    refute IERS::TaiUtcDrift.covers?(37_299)
  end

  def test_covers_is_true_at_the_first_mjd
    assert IERS::TaiUtcDrift.covers?(37_300)
  end

  def test_covers_is_false_at_the_drift_era_end
    refute IERS::TaiUtcDrift.covers?(41_317)
  end

  def test_covers_is_false_after_the_drift_era
    refute IERS::TaiUtcDrift.covers?(45_000)
  end

  def test_first_mjd_is_1961_01_01
    assert_equal 37_300, IERS::TaiUtcDrift::FIRST_MJD
  end
end
