# frozen_string_literal: true

module IERS
  module PolarMotion
    # @attr x [Float] pole x-coordinate in arcseconds
    # @attr y [Float] pole y-coordinate in arcseconds
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

      x = interpolate_field(window, query_mjd, method) { |e| best_pm(e, :x) }
      y = interpolate_field(window, query_mjd, method) { |e| best_pm(e, :y) }

      Entry.new(
        x: x, y: y,
        mjd: query_mjd,
        data_quality: derive_quality(window, :pm_flag)
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
            x: best_pm(e, :x),
            y: best_pm(e, :y),
            mjd: e.mjd,
            data_quality: EopParameter::FLAG_TO_QUALITY.fetch(
              e.pm_flag, :observed
            )
          )
        end.freeze
    end

    def best_pm(entry, component)
      case component
      when :x
        entry.bulletin_b_pm_x || entry.pm_x
      when :y
        entry.bulletin_b_pm_y || entry.pm_y
      end
    end

    private_class_method :best_pm
  end
end
