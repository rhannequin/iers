# frozen_string_literal: true

module IERS
  module PolarMotion
    # @attr x [Float] pole x-coordinate in arcseconds
    # @attr y [Float] pole y-coordinate in arcseconds
    # @attr mjd [Float] Modified Julian Date of the query
    # @attr data_quality [Symbol] +:observed+ or +:predicted+
    Entry = ::Data.define(:x, :y, :mjd, :data_quality) do
      # @return [Boolean]
      def observed?
        data_quality == :observed
      end

      # @return [Boolean]
      def predicted?
        data_quality == :predicted
      end
    end

    FLAG_TO_QUALITY = {
      "I" => :observed, "P" => :predicted
    }.freeze
    private_constant :FLAG_TO_QUALITY

    module_function

    # @param input [Time, Date, DateTime, nil]
    # @param jd [Float, nil] Julian Date
    # @param mjd [Float, nil] Modified Julian Date
    # @param interpolation [Symbol, nil] +:lagrange+ or +:linear+
    # @return [Entry]
    # @raise [OutOfRangeError]
    def at(input = nil, jd: nil, mjd: nil, interpolation: nil)
      query_mjd = TimeScale.to_mjd(input, jd: jd, mjd: mjd)
      entries = Data.finals_entries
      method = interpolation ||
        IERS.configuration.interpolation

      case method
      when :lagrange
        order = IERS.configuration.lagrange_order
        window = EopLookup.window(
          entries, query_mjd, order: order
        )
        x = interpolate_pm(window, query_mjd, :lagrange, :x)
        y = interpolate_pm(window, query_mjd, :lagrange, :y)
        quality = derive_quality(window)
      when :linear
        bracket = EopLookup.bracket(entries, query_mjd)
        x = interpolate_pm(bracket, query_mjd, :linear, :x)
        y = interpolate_pm(bracket, query_mjd, :linear, :y)
        quality = derive_quality(bracket)
      end

      Entry.new(
        x: x, y: y,
        mjd: query_mjd,
        data_quality: quality
      )
    end

    # @param start_date [Date]
    # @param end_date [Date]
    # @return [Array<Entry>]
    def between(start_date, end_date)
      start_mjd = TimeScale.to_mjd(start_date)
      end_mjd = TimeScale.to_mjd(end_date)
      entries = Data.finals_entries

      entries
        .select { |e| e.mjd.between?(start_mjd, end_mjd) }
        .map do |e|
          Entry.new(
            x: best_pm(e, :x),
            y: best_pm(e, :y),
            mjd: e.mjd,
            data_quality: FLAG_TO_QUALITY.fetch(
              e.pm_flag, :observed
            )
          )
        end.freeze
    end

    def interpolate_pm(window, query_mjd, method, component)
      xs = window.map(&:mjd)
      ys = window.map { |e| best_pm(e, component) }

      case method
      when :lagrange
        Interpolation.lagrange(xs, ys, query_mjd)
      when :linear
        Interpolation.linear(xs, ys, query_mjd)
      end
    end

    def best_pm(entry, component)
      case component
      when :x
        entry.bulletin_b_pm_x || entry.pm_x
      when :y
        entry.bulletin_b_pm_y || entry.pm_y
      end
    end

    def derive_quality(window_entries)
      if window_entries.any? { |e| e.pm_flag == "P" }
        :predicted
      else
        :observed
      end
    end

    private_class_method :interpolate_pm,
      :best_pm,
      :derive_quality
  end
end
