# frozen_string_literal: true

module C04
  Row = ::Data.define(:mjd, :x, :y, :ut1_utc)

  module_function

  # @param path [String] an EOP 20 C04 file (0h or 12h sampling)
  # @return [Array<Row>]
  def parse(path)
    File.foreach(path).filter_map do |line|
      next if line.start_with?("#") || line.strip.empty?

      fields = line.split
      Row.new(
        mjd: Float(fields[4]),
        x: Float(fields[5]),
        y: Float(fields[6]),
        ut1_utc: Float(fields[7])
      )
    end
  end

  # @param path [String]
  # @return [String] the header line naming the series and its sampling
  def title(path)
    File.foreach(path).first(2).last.delete_prefix("#").strip.squeeze(" ")
  end
end
