# frozen_string_literal: true

module IERS
  module DeltaT
    PRE_1972_MJD = 41317.0
    private_constant :PRE_1972_MJD

    module_function

    # @param input [Time, Date, DateTime, nil]
    # @param jd [Float, nil] Julian Date
    # @param mjd [Float, nil] Modified Julian Date
    # @return [Float] DeltaT (TT − UT1) in seconds
    # @raise [OutOfRangeError]
    def at(input = nil, jd: nil, mjd: nil)
      query_mjd = TimeScale.to_mjd(input, jd: jd, mjd: mjd)

      if query_mjd < PRE_1972_MJD
        raise OutOfRangeError.new(
          "DeltaT is only available from 1972 onward " \
          "(MJD #{PRE_1972_MJD})",
          requested_mjd: query_mjd
        )
      end

      tai_utc = LeapSecond.at(mjd: query_mjd)
      ut1_utc = UT1.at(mjd: query_mjd).ut1_utc

      tai_utc + TimeScale::TT_TAI - ut1_utc
    end
  end
end
