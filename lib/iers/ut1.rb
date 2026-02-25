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

    FLAG_TO_QUALITY = {"I" => :observed, "P" => :predicted}.freeze
    private_constant :FLAG_TO_QUALITY

    module_function

    def at(input = nil, jd: nil, mjd: nil)
      detailed_at(input, jd: jd, mjd: mjd).ut1_utc
    end

    def detailed_at(input = nil, jd: nil, mjd: nil)
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
        ut1_utc = Interpolation.lagrange(xs, ys, query_mjd)
        quality = derive_quality(window)
      when :linear
        bracket = EopLookup.bracket(entries, query_mjd)
        xs = bracket.map(&:mjd)
        ys = bracket.map(&:ut1_utc)
        ut1_utc = Interpolation.linear(xs, ys, query_mjd)
        quality = derive_quality(bracket)
      end

      Entry.new(
        ut1_utc: ut1_utc,
        mjd: query_mjd,
        data_quality: quality
      )
    end

    def between(start_date, end_date)
      start_mjd = TimeScale.to_mjd(start_date)
      end_mjd = TimeScale.to_mjd(end_date)
      entries = Data.finals_entries

      entries
        .select { |e| e.mjd.between?(start_mjd, end_mjd) }
        .map do |e|
          Entry.new(
            ut1_utc: e.ut1_utc,
            mjd: e.mjd,
            data_quality: FLAG_TO_QUALITY.fetch(e.ut1_flag, :observed)
          )
        end.freeze
    end

    def derive_quality(window_entries)
      if window_entries.any? { |e| e.ut1_flag == "P" }
        :predicted
      else
        :observed
      end
    end

    private_class_method :derive_quality
  end
end
