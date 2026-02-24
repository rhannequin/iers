# frozen_string_literal: true

module IERS
  module LeapSecond
    Entry = ::Data.define(:effective_date, :tai_utc)

    module_function

    def all
      IERS::Data.leap_second_entries.map do |parser_entry|
        Entry.new(
          effective_date: parser_entry.date,
          tai_utc: parser_entry.tai_utc
        )
      end.freeze
    end

    def table
      all
    end

    def at(input = nil, jd: nil, mjd: nil)
      query_mjd = TimeScale.to_mjd(input, jd: jd, mjd: mjd)
      parser_entries = IERS::Data.leap_second_entries

      first_mjd = parser_entries.first.mjd
      last_mjd = parser_entries.last.mjd

      if query_mjd < first_mjd
        raise OutOfRangeError.new(
          "Requested MJD #{query_mjd} is before the first leap second " \
          "entry (MJD #{first_mjd})",
          requested_mjd: query_mjd,
          available_range: first_mjd..last_mjd
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
