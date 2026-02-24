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
  end
end
