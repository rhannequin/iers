# frozen_string_literal: true

module IERS
  # @api private
  module Interpolation
    module_function

    # @param xs [Array<Float>] x-coordinates (exactly 2)
    # @param ys [Array<Float>] y-coordinates (exactly 2)
    # @param x [Float] interpolation point
    # @return [Float]
    def linear(xs, ys, x)
      unless xs.size == 2 && ys.size == 2
        raise ArgumentError, "linear interpolation requires exactly 2 points"
      end

      x0, x1 = xs
      y0, y1 = ys
      t = (x - x0) / (x1 - x0)
      (y0 + t * (y1 - y0)).to_f
    end

    # @param xs [Array<Float>] x-coordinates
    # @param ys [Array<Float>] y-coordinates
    # @param x [Float] interpolation point
    # @return [Float]
    def lagrange(xs, ys, x)
      n = xs.size

      unless n == ys.size
        raise ArgumentError, "xs and ys must have the same size"
      end

      unless n >= 2
        raise ArgumentError, "lagrange interpolation requires at least 2 points"
      end

      result = 0.0
      n.times do |i|
        basis = 1.0
        n.times do |j|
          next if i == j
          basis *= (x - xs[j]) / (xs[i] - xs[j])
        end
        result += ys[i] * basis
      end
      result.to_f
    end
  end
end
