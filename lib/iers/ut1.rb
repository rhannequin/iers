# frozen_string_literal: true

module IERS
  module UT1
    # @attr ut1_utc [Float] UT1−UTC in seconds
    # @attr mjd [Float] Modified Julian Date of the query
    # @attr data_quality [Symbol] +:observed+ or +:predicted+
    Entry = ::Data.define(:ut1_utc, :mjd, :data_quality) do
      include HasDate

      # @return [Boolean]
      def observed?
        data_quality == :observed
      end

      # @return [Boolean]
      def predicted?
        data_quality == :predicted
      end
    end

    FLAG_TO_QUALITY = {"I" => :observed, "P" => :predicted}.freeze
    private_constant :FLAG_TO_QUALITY

    module_function

    # @param input [Time, Date, DateTime, nil]
    # @param jd [Float, nil] Julian Date
    # @param mjd [Float, nil] Modified Julian Date
    # @param interpolation [Symbol, nil] +:lagrange+ or +:linear+
    # @return [Float] UT1−UTC in seconds
    # @raise [OutOfRangeError]
    def at(input = nil, jd: nil, mjd: nil, interpolation: nil)
      detailed_at(
        input,
        jd: jd,
        mjd: mjd,
        interpolation: interpolation
      ).ut1_utc
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
        window = EopLookup.window(
          entries,
          query_mjd,
          order: order
        )
        ut1_utc = interpolate_ut1(
          window,
          query_mjd,
          :lagrange
        )
        quality = derive_quality(window)
      when :linear
        bracket = EopLookup.bracket(entries, query_mjd)
        ut1_utc = interpolate_ut1(
          bracket,
          query_mjd,
          :linear
        )
        quality = derive_quality(bracket)
      end

      Entry.new(
        ut1_utc: ut1_utc,
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
            ut1_utc: best_ut1_utc(e),
            mjd: e.mjd,
            data_quality: FLAG_TO_QUALITY.fetch(e.ut1_flag, :observed)
          )
        end.freeze
    end

    def interpolate_ut1(window, query_mjd, method)
      xs = window.map(&:mjd)
      tai_utc_at_query = LeapSecond.at(mjd: query_mjd)
      ys = window.map do |e|
        best_ut1_utc(e) - LeapSecond.at(mjd: e.mjd)
      end

      ut1_tai = case method
      when :lagrange
        Interpolation.lagrange(xs, ys, query_mjd)
      when :linear
        Interpolation.linear(xs, ys, query_mjd)
      end

      ut1_tai + tai_utc_at_query
    end

    def best_ut1_utc(entry)
      entry.bulletin_b_ut1_utc || entry.ut1_utc
    end

    def derive_quality(window_entries)
      if window_entries.any? { |e| e.ut1_flag == "P" }
        :predicted
      else
        :observed
      end
    end

    private_class_method :interpolate_ut1,
      :best_ut1_utc,
      :derive_quality
  end
end
