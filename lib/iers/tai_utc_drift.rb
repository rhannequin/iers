# frozen_string_literal: true

module IERS
  # TAI-UTC from 1961-01-01 to 1972-01-01, when UTC was steered by rate
  # adjustments instead of whole leap seconds. In this era TAI-UTC is a linear
  # function of MJD, restarting at each published step, so a value is
  # +offset + (mjd - reference_mjd) * rate+.
  #
  # The table is closed: the last segment ends where Leap_Second.dat begins and
  # no new segment can ever be added.
  #
  # Coefficients from the USNO tai-utc.dat file, the same values ERFA carries in
  # dat.c. They are exact decimals, so they are stored as rationals rather than
  # floats.
  #
  # @api private
  module TaiUtcDrift
    # @attr start_mjd [Integer] first MJD the segment applies to
    # @attr offset [Rational] TAI-UTC in seconds at reference_mjd (not at
    #   start_mjd: several segments measure their rate from an earlier MJD)
    # @attr reference_mjd [Integer] the MJD the rate is measured from
    # @attr rate [Rational] seconds of TAI-UTC per day of MJD
    Segment = ::Data.define(:start_mjd, :offset, :reference_mjd, :rate)

    # 1961-01-01. Below this there is no published UTC, so TAI-UTC is undefined.
    FIRST_MJD = 37_300

    # 1972-01-01, where Leap_Second.dat takes over. The drift era stops here.
    LAST_MJD = 41_317

    module_function

    # @param mjd [Numeric]
    # @return [Rational] TAI-UTC in seconds
    def at(mjd)
      segment = SEGMENTS.reverse_each.find { |s| mjd >= s.start_mjd }

      segment.offset +
        (Rational(mjd) - segment.reference_mjd) * segment.rate
    end

    # Whether +at+ has a value for this MJD: 1961-01-01 up to but not including
    # 1972-01-01, where Leap_Second.dat takes over. A caller with a custom leap
    # second file starting after 1972 relies on the upper bound to fall through
    # to its own error rather than reading a stale drift value.
    #
    # @param mjd [Numeric]
    # @return [Boolean]
    def covers?(mjd)
      mjd >= FIRST_MJD && mjd < LAST_MJD
    end

    SEGMENTS = [
      Segment.new(
        start_mjd: 37_300,
        offset: Rational(14_228_180, 10_000_000),
        reference_mjd: 37_300,
        rate: Rational(1_296, 1_000_000)
      ),
      Segment.new(
        start_mjd: 37_512,
        offset: Rational(13_728_180, 10_000_000),
        reference_mjd: 37_300,
        rate: Rational(1_296, 1_000_000)
      ),
      Segment.new(
        start_mjd: 37_665,
        offset: Rational(18_458_580, 10_000_000),
        reference_mjd: 37_665,
        rate: Rational(11_232, 10_000_000)
      ),
      Segment.new(
        start_mjd: 38_334,
        offset: Rational(19_458_580, 10_000_000),
        reference_mjd: 37_665,
        rate: Rational(11_232, 10_000_000)
      ),
      Segment.new(
        start_mjd: 38_395,
        offset: Rational(32_401_300, 10_000_000),
        reference_mjd: 38_761,
        rate: Rational(1_296, 1_000_000)
      ),
      Segment.new(
        start_mjd: 38_486,
        offset: Rational(33_401_300, 10_000_000),
        reference_mjd: 38_761,
        rate: Rational(1_296, 1_000_000)
      ),
      Segment.new(
        start_mjd: 38_639,
        offset: Rational(34_401_300, 10_000_000),
        reference_mjd: 38_761,
        rate: Rational(1_296, 1_000_000)
      ),
      Segment.new(
        start_mjd: 38_761,
        offset: Rational(35_401_300, 10_000_000),
        reference_mjd: 38_761,
        rate: Rational(1_296, 1_000_000)
      ),
      Segment.new(
        start_mjd: 38_820,
        offset: Rational(36_401_300, 10_000_000),
        reference_mjd: 38_761,
        rate: Rational(1_296, 1_000_000)
      ),
      Segment.new(
        start_mjd: 38_942,
        offset: Rational(37_401_300, 10_000_000),
        reference_mjd: 38_761,
        rate: Rational(1_296, 1_000_000)
      ),
      Segment.new(
        start_mjd: 39_004,
        offset: Rational(38_401_300, 10_000_000),
        reference_mjd: 38_761,
        rate: Rational(1_296, 1_000_000)
      ),
      Segment.new(
        start_mjd: 39_126,
        offset: Rational(43_131_700, 10_000_000),
        reference_mjd: 39_126,
        rate: Rational(2_592, 1_000_000)
      ),
      Segment.new(
        start_mjd: 39_887,
        offset: Rational(42_131_700, 10_000_000),
        reference_mjd: 39_126,
        rate: Rational(2_592, 1_000_000)
      ),
      # Reached only by a direct TaiUtcDrift.at(41_317): LeapSecond.at's drift
      # branch requires query_mjd < 41_317. It pins the join to exactly 10,
      # matching Leap_Second.dat's first row; without it the 1968 segment would
      # give ~9.8922 here. Do not remove.
      Segment.new(
        start_mjd: 41_317,
        offset: Rational(10),
        reference_mjd: 41_317,
        rate: Rational(0)
      )
    ].freeze
  end
end
