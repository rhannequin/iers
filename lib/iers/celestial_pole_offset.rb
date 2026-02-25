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
      method = interpolation || IERS.configuration.interpolation

      case method
      when :lagrange
        order = IERS.configuration.lagrange_order
        window = EopLookup.window(
          entries, query_mjd, order: order
        )
        x = interpolate_cpo(window, query_mjd, :lagrange, :x)
        y = interpolate_cpo(window, query_mjd, :lagrange, :y)
        quality = derive_quality(window)
      when :linear
        bracket = EopLookup.bracket(entries, query_mjd)
        x = interpolate_cpo(bracket, query_mjd, :linear, :x)
        y = interpolate_cpo(bracket, query_mjd, :linear, :y)
        quality = derive_quality(bracket)
      end

      Entry.new(
        x: x,
        y: y,
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
            x: e.dx,
            y: e.dy,
            mjd: e.mjd,
            data_quality: FLAG_TO_QUALITY.fetch(e.nutation_flag, :observed)
          )
        end.freeze
    end

    def interpolate_cpo(window, query_mjd, method, component)
      xs = window.map(&:mjd)
      ys = window.map { |e| (component == :x) ? e.dx : e.dy }

      case method
      when :lagrange
        Interpolation.lagrange(xs, ys, query_mjd)
      when :linear
        Interpolation.linear(xs, ys, query_mjd)
      end
    end

    def derive_quality(window_entries)
      if window_entries.any? { |e| e.nutation_flag == "P" }
        :predicted
      else
        :observed
      end
    end

    private_class_method :interpolate_cpo, :derive_quality
  end
end
