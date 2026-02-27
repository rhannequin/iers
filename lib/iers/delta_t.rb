# frozen_string_literal: true

module IERS
  module DeltaT
    # @attr delta_t [Float] TT − UT1 in seconds
    # @attr mjd [Float] Modified Julian Date of the query
    # @attr source [Symbol] +:measured+ or +:estimated+
    Entry = ::Data.define(:delta_t, :mjd, :source) do
      # @return [Boolean]
      def measured? = source == :measured

      # @return [Boolean]
      def estimated? = source == :estimated
    end

    EARLIEST_YEAR = 1800.0
    PRE_1972_MJD = 41317.0
    DAYS_PER_JULIAN_YEAR = 365.25
    YEAR_J2000 = 2000.0

    # Espenak & Meeus (2014) polynomial segments for 1800–1972.
    # Each segment: [year_start, year_end, epoch, coefficients]
    # ΔT = c₀ + c₁·t + c₂·t² + ... where t = y − epoch
    # Reference: https://eclipsewise.com/help/deltatpoly2014.html
    POLYNOMIALS = [
      [1800.0, 1860.0, 1800.0, [
        13.72, -0.332447, 0.0068612, 0.0041116,
        -0.00037436, 0.0000121272, -0.0000001699, 0.000000000875
      ].freeze],
      [1860.0, 1900.0, 1860.0, [
        7.62, 0.5737, -0.251754, 0.01680668,
        -0.0004473624, 1.0 / 233174
      ].freeze],
      [1900.0, 1920.0, 1900.0, [
        -2.79, 1.494119, -0.0598939, 0.0061966, -0.000197
      ].freeze],
      [1920.0, 1941.0, 1920.0, [
        21.20, 0.84493, -0.076100, 0.0020936
      ].freeze],
      [1941.0, 1961.0, 1950.0, [
        29.07, 0.407, -1.0 / 233, 1.0 / 2547
      ].freeze],
      [1961.0, 1986.0, 1975.0, [
        45.45, 1.067, -1.0 / 260, -1.0 / 718
      ].freeze]
    ].freeze

    private_constant :EARLIEST_YEAR,
      :PRE_1972_MJD,
      :DAYS_PER_JULIAN_YEAR,
      :YEAR_J2000,
      :POLYNOMIALS

    module_function

    # @param input [Time, Date, DateTime, nil]
    # @param jd [Float, nil] Julian Date
    # @param mjd [Float, nil] Modified Julian Date
    # @return [Entry] DeltaT (TT − UT1) in seconds with source metadata
    # @raise [OutOfRangeError]
    def at(input = nil, jd: nil, mjd: nil)
      query_mjd = TimeScale.to_mjd(input, jd: jd, mjd: mjd)
      y = mjd_to_decimal_year(query_mjd)

      if y < EARLIEST_YEAR
        raise OutOfRangeError.new(
          "DeltaT is only available from #{EARLIEST_YEAR.to_i} onward",
          requested_mjd: query_mjd
        )
      end

      if query_mjd < PRE_1972_MJD
        Entry.new(
          delta_t: polynomial_delta_t(y),
          mjd: query_mjd,
          source: :estimated
        )
      else
        tai_utc = LeapSecond.at(mjd: query_mjd)
        ut1_utc = UT1.at(mjd: query_mjd).ut1_utc

        Entry.new(
          delta_t: tai_utc + TimeScale::TT_TAI - ut1_utc,
          mjd: query_mjd,
          source: :measured
        )
      end
    end

    def polynomial_delta_t(y)
      segment = POLYNOMIALS.find { |s| y < s[1] } || POLYNOMIALS.last
      t = y - segment[2]
      segment[3].reverse.reduce { |acc, c| acc * t + c }
    end

    def mjd_to_decimal_year(mjd)
      YEAR_J2000 + (mjd - TimeScale::MJD_J2000) / DAYS_PER_JULIAN_YEAR
    end

    private_class_method :polynomial_delta_t, :mjd_to_decimal_year
  end
end
