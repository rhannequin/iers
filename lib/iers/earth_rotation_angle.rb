# frozen_string_literal: true

module IERS
  module EarthRotationAngle
    # ERA at J2000.0 in fractional turns
    # (IERS Conventions 2010, eq. 5.15; IAU 2000 Resolution B1.8)
    ERA_AT_J2000 = 0.7790572732640

    # Ratio of universal to sidereal time
    # (IERS Conventions 2010, eq. 5.15; IAU 2000 Resolution B1.8)
    ERA_RATE = 1.00273781191135448

    TWO_PI = 2.0 * Math::PI

    private_constant :ERA_AT_J2000, :ERA_RATE, :TWO_PI

    module_function

    # @param input [Time, Date, DateTime, nil]
    # @param jd [Float, nil] Julian Date
    # @param mjd [Float, nil] Modified Julian Date
    # @param interpolation [Symbol, nil] +:lagrange+ or +:linear+
    # @return [Float] Earth Rotation Angle in radians, normalized to [0, 2π)
    # @raise [OutOfRangeError]
    def at(input = nil, jd: nil, mjd: nil, interpolation: nil)
      query_mjd = TimeScale.to_mjd(input, jd: jd, mjd: mjd)
      ut1_utc = UT1.at(mjd: query_mjd, interpolation: interpolation).ut1_utc

      du = query_mjd - TimeScale::MJD_J2000 +
        ut1_utc / TimeScale::SECONDS_PER_DAY

      # IERS Conventions 2010, eq. 5.15
      turns = ERA_AT_J2000 + ERA_RATE * du
      era = (turns % 1.0) * TWO_PI
      era += TWO_PI if era < 0.0
      era
    end
  end
end
