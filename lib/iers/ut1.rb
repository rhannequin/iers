# frozen_string_literal: true

module IERS
  module UT1
    Entry = ::Data.define(:ut1_utc, :mjd, :data_quality) do
      def observed?
        data_quality == :observed
      end

      def predicted?
        data_quality == :predicted
      end
    end

    module_function

    def at(input = nil, jd: nil, mjd: nil)
      query_mjd = TimeScale.to_mjd(input, jd: jd, mjd: mjd)
      entries = Data.finals_entries
      config = IERS.configuration

      case config.interpolation
      when :lagrange
        window = EopLookup.window(
          entries, query_mjd, order: config.lagrange_order
        )
        xs = window.map(&:mjd)
        ys = window.map(&:ut1_utc)
        Interpolation.lagrange(xs, ys, query_mjd)
      when :linear
        bracket = EopLookup.bracket(entries, query_mjd)
        xs = bracket.map(&:mjd)
        ys = bracket.map(&:ut1_utc)
        Interpolation.linear(xs, ys, query_mjd)
      end
    end
  end
end
