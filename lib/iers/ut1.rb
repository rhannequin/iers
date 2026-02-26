# frozen_string_literal: true

module IERS
  module UT1
    # @attr ut1_utc [Float] UT1−UTC in seconds
    # @attr mjd [Float] Modified Julian Date of the query
    # @attr data_quality [Symbol] +:observed+ or +:predicted+
    Entry = ::Data.define(:ut1_utc, :mjd, :data_quality) do
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

      ut1_utc = interpolate_ut1(window, query_mjd, method)

      Entry.new(
        ut1_utc: ut1_utc,
        mjd: query_mjd,
        data_quality: derive_quality(window, :ut1_flag)
      )
    end

    # @param start_date [Date]
    # @param end_date [Date]
    # @return [Enumerator::Lazy<Entry>]
    def between(start_date, end_date)
      start_mjd = TimeScale.to_mjd(start_date)
      end_mjd = TimeScale.to_mjd(end_date)
      entries = Data.finals_entries

      EopLookup
        .range(entries, start_mjd, end_mjd)
        .lazy
        .map do |e|
          Entry.new(
            ut1_utc: best_ut1_utc(e),
            mjd: e.mjd,
            data_quality: EopParameter::FLAG_TO_QUALITY.fetch(e.ut1_flag, :observed)
          )
        end
    end

    def interpolate_ut1(window, query_mjd, method)
      leap_entries = Data.leap_second_entries
      tai_utc_at_query = tai_utc_for(leap_entries, query_mjd)

      ut1_tai = interpolate_field(window, query_mjd, method) do |e|
        best_ut1_utc(e) - tai_utc_for(leap_entries, e.mjd)
      end

      ut1_tai + tai_utc_at_query
    end

    def tai_utc_for(entries, mjd)
      index = entries.bsearch_index { |e| e.mjd > mjd }
      index.nil? ? entries.last.tai_utc : entries[index - 1].tai_utc
    end

    def best_ut1_utc(entry)
      entry.bulletin_b_ut1_utc || entry.ut1_utc
    end

    private_class_method :interpolate_ut1,
      :tai_utc_for,
      :best_ut1_utc
  end
end
