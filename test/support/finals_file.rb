# frozen_string_literal: true

require "date"

module FinalsFile
  module_function

  # @param rows [Array<Array(Float, Float, Float, Float)>] MJD, x ("), y ("),
  #   UT1-UTC (s)
  # @return [String]
  def render(rows)
    rows.sort_by(&:first).map { |row| line(*row) }.join
  end

  # @param path [String, Pathname]
  # @param rows [Array<Array(Float, Float, Float, Float)>]
  # @return [void]
  def write(path, rows)
    File.write(path, render(rows))
  end

  # @param mjd [Float]
  # @param x [Float]
  # @param y [Float]
  # @param ut1_utc [Float]
  # @return [String]
  def line(mjd, x, y, ut1_utc)
    date = Date.jd((mjd + 2_400_001).floor)

    format(
      "%2d%2d%2d %8.2f I %9.6f%9.6f %9.6f%9.6f  I%10.7f%10.7f\n",
      date.year % 100, date.month, date.day, mjd,
      x, 0.0, y, 0.0, ut1_utc, 0.0
    )
  end
end
