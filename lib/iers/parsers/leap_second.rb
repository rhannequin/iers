# frozen_string_literal: true

require "date"

module IERS
  module Parsers
    module LeapSecond
      Entry = ::Data.define(:mjd, :date, :tai_utc)

      # @attr expires_on [Date, nil]
      # @attr updated_through [String, nil]
      Metadata = ::Data.define(:expires_on, :updated_through)

      # @attr entries [Array<Entry>]
      # @attr metadata [Metadata]
      Table = ::Data.define(:entries, :metadata)

      EXPIRES_ON = /File expires on\s+(\d{1,2})\s+([A-Za-z]+)\s+(\d{4})/i
      UPDATED_THROUGH = /\AUpdated through\s+(.+?)\s*\z/i
      COMMENT_PREFIX = /\A#+\s*/

      module_function

      # @return [Table]
      def parse(path)
        path = Pathname(path)

        unless path.exist?
          raise FileNotFoundError.new(
            "File not found: #{path}",
            path: path.to_s
          )
        end

        entries = []
        expires_on = nil
        updated_through = nil

        path.each_line.with_index(1) do |line, line_number|
          stripped = line.scrub.strip
          next if stripped.empty?

          if stripped.start_with?("#")
            comment = stripped.sub(COMMENT_PREFIX, "")
            expires_on ||= parse_expiry(comment)
            updated_through ||= parse_updated_through(comment)
            next
          end

          entries << parse_line(line, path, line_number)
        end

        Table.new(
          entries: entries.freeze,
          metadata: Metadata.new(
            expires_on: expires_on,
            updated_through: updated_through
          )
        )
      end

      def parse_line(line, path, line_number)
        parts = line.split

        Entry.new(
          mjd: Float(parts[0]),
          date: Date.new(
            Integer(parts[3]),
            Integer(parts[2]),
            Integer(parts[1])
          ),
          tai_utc: Integer(parts[4])
        )
      rescue ArgumentError, TypeError => e
        raise ParseError.new(
          "Failed to parse line #{line_number}: #{e.message}",
          path: path.to_s,
          line_number: line_number
        )
      end

      # @return [Date, nil]
      def parse_expiry(comment)
        match = EXPIRES_ON.match(comment)
        return nil if match.nil?

        month = Date::MONTHNAMES.index do |name|
          name&.casecmp?(match[2])
        end
        return nil if month.nil?

        Date.new(Integer(match[3], 10), month, Integer(match[1], 10))
      rescue ArgumentError
        nil
      end

      # @return [String, nil]
      def parse_updated_through(comment)
        match = UPDATED_THROUGH.match(comment)
        match && match[1]
      end

      private_class_method :parse_line, :parse_expiry, :parse_updated_through
    end
  end
end
