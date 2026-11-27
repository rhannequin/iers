# frozen_string_literal: true

module Stats
  module_function

  # @param differences [Array<Float>]
  # @return [Hash{String => Float}, nil] largest absolute value, 99th
  #   percentile of the absolute values, and root mean square; nil when there
  #   are no differences
  def summarize(differences)
    return nil if differences.empty?

    sorted = differences.map(&:abs).sort
    {
      "max" => sorted.last.round(3),
      "p99" => sorted[((sorted.size - 1) * 0.99).round].round(3),
      "rms" => Math.sqrt(differences.sum { |d| d * d } / differences.size).round(3)
    }
  end
end
