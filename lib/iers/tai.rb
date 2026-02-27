# frozen_string_literal: true

module IERS
  module TAI
    module_function

    # Convert a UTC instant to TAI.
    #
    # @param input [Time, Date, DateTime, nil]
    # @param jd [Float, nil] Julian Date
    # @param mjd [Float, nil] Modified Julian Date
    # @return [Float] Modified Julian Date in TAI scale
    # @raise [OutOfRangeError]
    def utc_to_tai(input = nil, jd: nil, mjd: nil)
      utc_mjd = TimeScale.to_mjd(input, jd: jd, mjd: mjd)
      tai_utc = LeapSecond.at(mjd: utc_mjd)
      utc_mjd + tai_utc / TimeScale::SECONDS_PER_DAY
    end

    # Convert a TAI instant to UTC.
    #
    # Uses the TAI instant for an initial leap second lookup, then
    # verifies the offset at the derived UTC. If TAI and UTC straddle
    # a leap second boundary the first lookup may be off by one second;
    # the verification step corrects this exactly.
    #
    # @param input [Time, Date, DateTime, nil]
    # @param jd [Float, nil] Julian Date
    # @param mjd [Float, nil] Modified Julian Date
    # @return [Float] Modified Julian Date in UTC scale
    # @raise [OutOfRangeError]
    def tai_to_utc(input = nil, jd: nil, mjd: nil)
      tai_mjd = TimeScale.to_mjd(input, jd: jd, mjd: mjd)

      initial_offset = LeapSecond.at(mjd: tai_mjd)
      utc_mjd = tai_mjd - initial_offset / TimeScale::SECONDS_PER_DAY

      verified_offset = LeapSecond.at(mjd: utc_mjd)
      return utc_mjd if verified_offset == initial_offset

      tai_mjd - verified_offset / TimeScale::SECONDS_PER_DAY
    end
  end
end
