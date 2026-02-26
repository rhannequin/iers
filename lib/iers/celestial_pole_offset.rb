# frozen_string_literal: true

module IERS
  module CelestialPoleOffset
    # @attr x [Float] dX correction in milliarcseconds
    # @attr y [Float] dY correction in milliarcseconds
    # @attr mjd [Float] Modified Julian Date of the query
    # @attr data_quality [Symbol] +:observed+ or +:predicted+
    Entry = ::Data.define(:x, :y, :mjd, :data_quality) do
      include HasDate
      include HasDataQuality
    end

    extend EopParameter

    module_function

    # @param input [Time, Date, DateTime, nil]
    # @param jd [Float, nil] Julian Date
    # @param mjd [Float, nil] Modified Julian Date
    # @param interpolation [Symbol, nil] +:lagrange+ or +:linear+
    # @return [Entry]
    # @raise [OutOfRangeError]
    def at(input = nil, jd: nil, mjd: nil, interpolation: nil)
      query_mjd, window, method = resolve(
        input,
        jd: jd,
        mjd: mjd,
        interpolation: interpolation
      )

      x = interpolate_field(window, query_mjd, method) { |e| e.dx }
      y = interpolate_field(window, query_mjd, method) { |e| e.dy }

      Entry.new(
        x: x, y: y,
        mjd: query_mjd,
        data_quality: derive_quality(window, :nutation_flag)
      )
    end

    # @param start_date [Date]
    # @param end_date [Date]
    # @return [Array<Entry>]
    def between(start_date, end_date)
      start_mjd = TimeScale.to_mjd(start_date)
      end_mjd = TimeScale.to_mjd(end_date)
      entries = Data.finals_entries

      EopLookup
        .range(entries, start_mjd, end_mjd)
        .map do |e|
          Entry.new(
            x: e.dx,
            y: e.dy,
            mjd: e.mjd,
            data_quality: EopParameter::FLAG_TO_QUALITY.fetch(e.nutation_flag, :observed)
          )
        end.freeze
    end
  end
end
