# frozen_string_literal: true

require "date"

module IERS
  module Parsers
    module LeapSecond
      Entry = Data.define(:mjd, :date, :tai_utc)

      module_function

      def parse(path)
        path = Pathname(path)

        unless path.exist?
          raise FileNotFoundError.new(
            "File not found: #{path}",
            path: path.to_s
          )
        end

        entries = []

        path.each_line.with_index(1) do |line, line_number|
          next if line.strip.empty? || line.strip.start_with?("#")

          entries << parse_line(line, path, line_number)
        end

        entries.freeze
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

      private_class_method :parse_line
    end
  end
end
