# frozen_string_literal: true

module IERS
  module LengthOfDay
    # @attr length_of_day [Float] excess LOD in seconds
    # @attr mjd [Float] Modified Julian Date of the query
    # @attr data_quality [Symbol] +:observed+ or +:predicted+
    Entry = ::Data.define(:length_of_day, :mjd, :data_quality) do
      include HasDate
      include HasDataQuality
    end

    FLAG_TO_QUALITY = {"I" => :observed, "P" => :predicted}.freeze
    private_constant :FLAG_TO_QUALITY

    module_function

    # @param input [Time, Date, DateTime, nil]
    # @param jd [Float, nil] Julian Date
    # @param mjd [Float, nil] Modified Julian Date
    # @param interpolation [Symbol, nil] +:lagrange+ or +:linear+
    # @return [Float] excess LOD in seconds
    # @raise [OutOfRangeError]
    def at(input = nil, jd: nil, mjd: nil, interpolation: nil)
      detailed_at(
        input,
        jd: jd,
        mjd: mjd,
        interpolation: interpolation
      ).length_of_day
    end

    # @param input [Time, Date, DateTime, nil]
    # @param jd [Float, nil] Julian Date
    # @param mjd [Float, nil] Modified Julian Date
    # @param interpolation [Symbol, nil] +:lagrange+ or +:linear+
    # @return [Entry]
    # @raise [OutOfRangeError]
    def detailed_at(input = nil, jd: nil, mjd: nil, interpolation: nil)
      query_mjd = TimeScale.to_mjd(input, jd: jd, mjd: mjd)
      entries = Data.finals_entries
      method = interpolation || IERS.configuration.interpolation

      case method
      when :lagrange
        order = IERS.configuration.lagrange_order
        window = EopLookup.window(entries, query_mjd, order: order)
        lod = interpolate_lod(window, query_mjd, :lagrange)
        quality = derive_quality(window)
      when :linear
        bracket = EopLookup.bracket(entries, query_mjd)
        lod = interpolate_lod(bracket, query_mjd, :linear)
        quality = derive_quality(bracket)
      end

      Entry.new(
        length_of_day: lod,
        mjd: query_mjd,
        data_quality: quality
      )
    end

    def interpolate_lod(window, query_mjd, method)
      xs = window.map(&:mjd)
      ys = window.map { |e| e.lod / 1000.0 }

      case method
      when :lagrange then Interpolation.lagrange(xs, ys, query_mjd)
      when :linear then Interpolation.linear(xs, ys, query_mjd)
      end
    end

    def derive_quality(window_entries)
      if window_entries.any? { |e| e.ut1_flag == "P" }
        :predicted
      else
        :observed
      end
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
            length_of_day: e.lod / 1000.0,
            mjd: e.mjd,
            data_quality: FLAG_TO_QUALITY.fetch(e.ut1_flag, :observed)
          )
        end.freeze
    end

    private_class_method :interpolate_lod, :derive_quality
  end
end
