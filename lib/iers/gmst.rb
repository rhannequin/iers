# frozen_string_literal: true

module IERS
  module GMST
    TWO_PI = 2.0 * Math::PI

    # IERS Conventions 2010, eq. 5.32 (arcseconds)
    POLYNOMIAL = [
      0.014506,
      4612.156534,
      1.3915817,
      -0.00000044,
      -0.000029956,
      -0.0000000368
    ].freeze

    private_constant :TWO_PI, :POLYNOMIAL

    module_function

    # @param input [Time, Date, DateTime, nil]
    # @param jd [Float, nil] Julian Date
    # @param mjd [Float, nil] Modified Julian Date
    # @param interpolation [Symbol, nil] +:lagrange+ or +:linear+
    # @return [Float] Greenwich Mean Sidereal Time in radians, norm. to [0, 2π)
    # @raise [OutOfRangeError]
    def at(input = nil, jd: nil, mjd: nil, interpolation: nil)
      query_mjd = TimeScale.to_mjd(input, jd: jd, mjd: mjd)
      era = EarthRotationAngle.at(mjd: query_mjd, interpolation: interpolation)

      tai_utc = LeapSecond.at(mjd: query_mjd)
      tt_mjd = query_mjd +
        (tai_utc + TimeScale::TT_TAI) / TimeScale::SECONDS_PER_DAY
      t = (tt_mjd - TimeScale::MJD_J2000) / TimeScale::DAYS_PER_JULIAN_CENTURY

      poly = POLYNOMIAL.reverse.reduce { |acc, c| acc * t + c }
      gmst = (era + poly * TimeScale::ARCSEC_TO_RAD) % TWO_PI
      gmst += TWO_PI if gmst < 0.0
      gmst
    end
  end
end
