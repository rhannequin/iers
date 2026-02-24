# frozen_string_literal: true

require "date"

module IERS
  module TimeScale
    JD_MJD_OFFSET = 2_400_000.5

    module_function

    def to_mjd(input = nil, jd: nil, mjd: nil)
      if mjd
        Float(mjd)
      elsif jd
        Float(jd) - JD_MJD_OFFSET
      elsif input.is_a?(Time)
        input.to_datetime.ajd.to_f - JD_MJD_OFFSET
      elsif input.is_a?(DateTime)
        input.ajd.to_f - JD_MJD_OFFSET
      elsif input.is_a?(Date)
        input.ajd.to_f - JD_MJD_OFFSET
      else
        raise ArgumentError,
          "Expected Time, Date, DateTime, jd: or mjd: keyword, " \
          "got #{input.inspect}"
      end
    end
  end
end
