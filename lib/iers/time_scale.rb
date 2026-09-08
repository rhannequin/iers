# frozen_string_literal: true

require "date"

module IERS
  # @api private
  module TimeScale
    JD_MJD_OFFSET = 2_400_000.5
    JD_J2000 = 2_451_545.0
    MJD_J2000 = 51_544.5
    DAYS_PER_JULIAN_CENTURY = 36_525.0
    SECONDS_PER_DAY = 86_400.0
    ARCSEC_TO_RAD = Math::PI / 648_000.0
    TT_TAI = 32.184 # seconds

    module_function

    # @param mjd [Float] Modified Julian Date
    # @return [Date]
    def to_date(mjd)
      Date.jd((mjd.floor + JD_MJD_OFFSET).ceil)
    end

    # @param input [Time, Date, DateTime, nil]
    # @param jd [Float, nil] Julian Date
    # @param mjd [Float, nil] Modified Julian Date
    # @return [Float] Modified Julian Date
    # @raise [ArgumentError] if no valid input is provided
    def to_mjd(input = nil, jd: nil, mjd: nil)
      if mjd
        to_float(mjd)
      elsif jd
        to_float(jd) - JD_MJD_OFFSET
      elsif input.is_a?(Time)
        input.to_datetime.ajd.to_f - JD_MJD_OFFSET
      elsif input.is_a?(Date)
        input.ajd.to_f - JD_MJD_OFFSET
      else
        raise ArgumentError,
          "Expected Time, Date, DateTime, jd: or mjd: keyword, " \
          "got #{input.inspect}"
      end
    end

    # A date as a Float, without writing to the caller's stderr on the way.
    #
    # +Kernel#Float+ warns "Integer out of Float range" for a magnitude that
    # does not fit one, and for a Rational whose numerator or denominator does
    # not either, so a date far outside the data announced itself before being
    # refused. An Integer or a Rational is measured first and converted
    # directly, which is quiet; everything else still goes through
    # +Kernel#Float+, which is what refuses a String or a nil.
    #
    # The value is unchanged: a magnitude past the range of a Float was an
    # Infinity before and is one now.
    #
    # @param value [Numeric, String] the date to read
    # @return [Float]
    # @raise [ArgumentError, TypeError] if it is not a number
    def to_float(value)
      case value
      when Float then value
      when Integer, Rational
        return value.to_f unless value.abs > Float::MAX

        value.negative? ? -Float::INFINITY : Float::INFINITY
      else Float(value)
      end
    end
  end
end
