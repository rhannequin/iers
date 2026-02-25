# frozen_string_literal: true

module IERS
  module Interpolation
    module_function

    def linear(xs, ys, x)
      unless xs.size == 2 && ys.size == 2
        raise ArgumentError, "linear interpolation requires exactly 2 points"
      end

      x0, x1 = xs
      y0, y1 = ys
      t = (x - x0) / (x1 - x0)
      (y0 + t * (y1 - y0)).to_f
    end
  end
end
