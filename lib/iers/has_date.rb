# frozen_string_literal: true

module IERS
  # @api private
  module HasDate
    # @return [Date]
    def date
      TimeScale.to_date(mjd)
    end
  end
end
