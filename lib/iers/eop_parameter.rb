# frozen_string_literal: true

module IERS
  # @api private
  module EopParameter
    FLAG_TO_QUALITY = {"I" => :observed, "P" => :predicted}.freeze

    def resolve(input, jd:, mjd:, interpolation:)
      query_mjd = TimeScale.to_mjd(input, jd: jd, mjd: mjd)
      entries = Data.finals_entries
      method = interpolation || IERS.configuration.interpolation

      window = case method
      when :lagrange
        order = IERS.configuration.lagrange_order
        EopLookup.window(entries, query_mjd, order: order)
      when :linear
        EopLookup.bracket(entries, query_mjd)
      end

      [query_mjd, window, method]
    end

    def interpolate_field(window, query_mjd, method)
      xs = window.map(&:mjd)
      ys = window.map { |e| yield e }

      case method
      when :lagrange then Interpolation.lagrange(xs, ys, query_mjd)
      when :linear then Interpolation.linear(xs, ys, query_mjd)
      end
    end

    def derive_quality(window, flag)
      if window.any? { |e| e.public_send(flag) == "P" }
        :predicted
      else
        :observed
      end
    end
  end
end
