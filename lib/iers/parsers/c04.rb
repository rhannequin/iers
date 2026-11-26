# frozen_string_literal: true

require "date"

module IERS
  module Parsers
    module C04
      Entry = ::Data.define(
        :date, :mjd,
        :pm_x, :pm_y, :ut1_utc, :dx, :dy, :pm_x_rate, :pm_y_rate, :lod,
        :pm_x_error, :pm_y_error, :ut1_utc_error, :dx_error, :dy_error,
        :pm_x_rate_error, :pm_y_rate_error, :lod_error
      )

      FIELD_COUNT = 21
      HEADER_PREFIX = "# YR"
      HEADER_COLUMNS = ["dX(\")", "dY(\")"].freeze

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
        header_seen = false

        path.each_line.with_index(1) do |raw, line_number|
          line = raw.scrub
          next if line.strip.empty?

          if line.start_with?("#")
            if line.start_with?(HEADER_PREFIX)
              check_header!(line, path, line_number)
              header_seen = true
            end
            next
          end

          unless header_seen
            raise ParseError.new(
              "Failed to parse line #{line_number}: no column header " \
              "before the first data line",
              path: path.to_s,
              line_number: line_number
            )
          end

          entries << parse_line(line, path, line_number)
        end

        entries.freeze
      end

      def check_header!(line, path, line_number)
        columns = line.split
        missing = HEADER_COLUMNS.reject { |column| columns.include?(column) }
        return if missing.empty?

        raise ParseError.new(
          "Failed to parse line #{line_number}: expected columns " \
          "#{HEADER_COLUMNS.join(", ")}, missing #{missing.join(", ")}",
          path: path.to_s,
          line_number: line_number
        )
      end

      def parse_line(line, path, line_number)
        fields = line.split

        unless fields.size == FIELD_COUNT
          raise ParseError.new(
            "Failed to parse line #{line_number}: expected " \
            "#{FIELD_COUNT} fields, got #{fields.size}",
            path: path.to_s,
            line_number: line_number
          )
        end

        year, month, day, hour = fields[0, 4].map { |f| Integer(f, 10) }

        unless hour.zero?
          raise ParseError.new(
            "Failed to parse line #{line_number}: expected values at 0h " \
            "UTC, got #{hour}h",
            path: path.to_s,
            line_number: line_number
          )
        end

        values = fields[4..].map { |f| Float(f) }

        Entry.new(
          Date.new(year, month, day),
          *values
        )
      rescue ArgumentError, TypeError => e
        raise ParseError.new(
          "Failed to parse line #{line_number}: #{e.message}",
          path: path.to_s,
          line_number: line_number
        )
      end

      private_class_method :check_header!, :parse_line
    end
  end
end
