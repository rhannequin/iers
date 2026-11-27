# frozen_string_literal: true

require "json"
require_relative "finals_file"

module ReferenceComparison
  FIXTURES = Pathname(__dir__).join("..", "fixtures", "references")
  LEAP_SECONDS = Pathname(__dir__).join("..", "..", "data", "Leap_Second.dat")
  LEAP_SECOND_MJDS = IERS::Parsers::LeapSecond
    .parse(LEAP_SECONDS).entries.map(&:mjd).freeze

  module_function

  # @param name [String] fixture name, without extension
  # @return [Hash]
  def load_reference(name)
    JSON.parse(FIXTURES.join("#{name}.json").read).freeze
  end

  # @param rows [Array<Array(Float, Float, Float, Float)>] MJD, x ("), y ("),
  #   UT1-UTC (s)
  # @param lagrange_order [Integer, nil]
  # @yield with the gem reading +rows+ as its finals data
  # @return [Object] the block's value
  def with_finals(rows, lagrange_order: nil)
    Dir.mktmpdir do |dir|
      path = File.join(dir, "finals.dat")
      FinalsFile.write(path, rows)
      IERS.configure do |config|
        config.eop_source = :finals
        config.finals_path = path
        config.leap_second_path = LEAP_SECONDS
        config.lagrange_order = lagrange_order if lagrange_order
      end
      yield
    ensure
      IERS.reset_configuration!
    end
  end

  # @param differences [Array<Float>]
  # @return [Hash{Symbol => Float}] largest absolute value and root mean square
  def summarize(differences)
    {
      max: differences.map(&:abs).max,
      rms: Math.sqrt(differences.sum { |d| d * d } / differences.size)
    }
  end

  # @param differences [Array<Float>]
  # @param max [Float]
  # @param rms [Float]
  # @param label [String]
  # @param unit [String]
  # @return [void]
  def assert_differences_within(differences, max:, rms:, label:, unit:)
    refute_empty differences, "#{label}: no cases"

    summary = summarize(differences)
    report = format(
      "%s over %d cases: max %.6g %s, RMS %.6g %s",
      label, differences.size, summary[:max], unit, summary[:rms], unit
    )

    assert_operator summary[:max], :<=, max, "#{report} (max allowed #{max})"
    assert_operator summary[:rms], :<=, rms, "#{report} (RMS allowed #{rms})"
  end
end
