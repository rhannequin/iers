# frozen_string_literal: true

require "date"

module IERS
  module Parsers
    module Finals
      Entry = Data.define(
        :date, :mjd,
        :pm_flag, :pm_x, :pm_x_error, :pm_y, :pm_y_error,
        :ut1_flag, :ut1_utc, :ut1_utc_error,
        :lod, :lod_error,
        :nutation_flag, :dx, :dx_error, :dy, :dy_error,
        :bulletin_b_pm_x, :bulletin_b_pm_y, :bulletin_b_ut1_utc,
        :bulletin_b_dx, :bulletin_b_dy
      )

      MJD_Y2K_PIVOT = 51544.0

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
          next if line.strip.empty?

          entries << parse_line(line, path, line_number)
        end

        entries.freeze
      end

      def parse_line(line, path, line_number)
        mjd = parse_float(line, 7, 8)
        yy = parse_int(line, 0, 2)
        month = parse_int(line, 2, 2)
        day = parse_int(line, 4, 2)
        year = (mjd < MJD_Y2K_PIVOT) ? 1900 + yy : 2000 + yy

        Entry.new(
          date: Date.new(year, month, day),
          mjd: mjd,
          pm_flag: parse_flag(line, 16),
          pm_x: parse_float(line, 18, 9),
          pm_x_error: parse_float(line, 27, 9),
          pm_y: parse_float(line, 37, 9),
          pm_y_error: parse_float(line, 46, 9),
          ut1_flag: parse_flag(line, 57),
          ut1_utc: parse_float(line, 58, 10),
          ut1_utc_error: parse_float(line, 68, 10),
          lod: parse_optional_float(line, 79, 7),
          lod_error: parse_optional_float(line, 86, 7),
          nutation_flag: parse_optional_flag(line, 95),
          dx: parse_optional_float(line, 97, 9),
          dx_error: parse_optional_float(line, 106, 9),
          dy: parse_optional_float(line, 116, 9),
          dy_error: parse_optional_float(line, 125, 9),
          bulletin_b_pm_x: parse_optional_float(line, 134, 10),
          bulletin_b_pm_y: parse_optional_float(line, 144, 10),
          bulletin_b_ut1_utc: parse_optional_float(line, 154, 11),
          bulletin_b_dx: parse_optional_float(line, 165, 10),
          bulletin_b_dy: parse_optional_float(line, 175, 10)
        )
      rescue ArgumentError, TypeError => e
        raise ParseError.new(
          "Failed to parse line #{line_number}: #{e.message}",
          path: path.to_s,
          line_number: line_number
        )
      end

      def parse_float(line, offset, length)
        Float(line[offset, length])
      end

      def parse_int(line, offset, length)
        Integer(line[offset, length])
      end

      def parse_flag(line, offset)
        line[offset, 1].strip
      end

      def parse_optional_float(line, offset, length)
        raw = line[offset, length]
        return nil if raw.nil? || raw.strip.empty?

        Float(raw)
      end

      def parse_optional_flag(line, offset)
        raw = line[offset, 1]
        return nil if raw.nil? || raw.strip.empty?

        raw.strip
      end

      private_class_method :parse_line,
        :parse_float,
        :parse_int,
        :parse_flag,
        :parse_optional_float,
        :parse_optional_flag
    end
  end
end
