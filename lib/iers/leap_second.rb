# frozen_string_literal: true

module IERS
  module LeapSecond
    # @attr effective_date [Date]
    # @attr tai_utc [Integer] cumulative TAI−UTC offset in seconds
    Entry = ::Data.define(:effective_date, :tai_utc)

    @mutex = Mutex.new
    @all = nil

    module_function

    # @return [Array<Entry>]
    def all
      @mutex.synchronize do
        @all ||= IERS::Data.leap_second_entries.map do |parser_entry|
          Entry.new(
            effective_date: parser_entry.date,
            tai_utc: parser_entry.tai_utc
          )
        end.freeze
      end
    end

    # @return [void]
    def clear_cached!
      @mutex.synchronize do
        @all = nil
      end
    end

    # @return [Date, nil]
    def expires_on
      IERS::Data.leap_second_metadata.expires_on
    end

    # @param as_of [Date]
    # @return [Boolean]
    def expired?(as_of: Date.today)
      expiry = expires_on
      return false if expiry.nil?

      as_of > expiry
    end

    # @return [String, nil]
    def updated_through
      IERS::Data.leap_second_metadata.updated_through
    end

    # @return [Entry, nil]
    def next_scheduled
      today = Date.today
      all.find { |entry| entry.effective_date > today }
    end

    # TAI−UTC covers 1961-01-01 onward. From 1972 the value is a whole number
    # of seconds read from Leap_Second.dat and returned as an Integer. Between
    # 1961 and 1972 UTC was steered by rate adjustments rather than whole leap
    # seconds, so the value is a fraction of a second returned as a Rational.
    #
    # @param input [Time, Date, DateTime, nil]
    # @param jd [Float, nil] Julian Date
    # @param mjd [Float, nil] Modified Julian Date
    # @return [Integer, Rational] TAI−UTC in seconds
    # @raise [OutOfRangeError] before 1961-01-01
    def at(input = nil, jd: nil, mjd: nil)
      query_mjd = TimeScale.to_mjd(input, jd: jd, mjd: mjd)
      parser_entries = IERS::Data.leap_second_entries

      first_mjd = parser_entries.first.mjd
      last_mjd = parser_entries.last.mjd

      if query_mjd < first_mjd
        return TaiUtcDrift.at(query_mjd) if TaiUtcDrift.covers?(query_mjd)

        raise OutOfRangeError.new(
          "Requested MJD #{query_mjd} is before TAI−UTC was defined " \
          "(MJD #{TaiUtcDrift::FIRST_MJD}, 1961-01-01; no published UTC " \
          "before then)",
          requested_mjd: query_mjd,
          available_range: TaiUtcDrift::FIRST_MJD..last_mjd
        )
      end

      index = parser_entries.bsearch_index { |e| e.mjd > query_mjd }

      if index.nil?
        parser_entries.last.tai_utc
      else
        parser_entries[index - 1].tai_utc
      end
    end
  end
end
