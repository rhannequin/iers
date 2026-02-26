# frozen_string_literal: true

module IERS
  module PolarMotion
    ARCSEC_TO_RAD = Math::PI / 648_000.0

    # TIO locator rate in arcseconds per Julian century
    # (IERS Conventions 2010, eq. 5.13)
    S_PRIME_RATE = -0.000047

    # @attr x [Float] pole x-coordinate in arcseconds
    # @attr y [Float] pole y-coordinate in arcseconds
    # @attr mjd [Float] Modified Julian Date of the query
    # @attr data_quality [Symbol] +:observed+ or +:predicted+
    Entry = ::Data.define(:x, :y, :mjd, :data_quality) do
      include HasDate
      include HasDataQuality

      # Polar motion rotation matrix W per IERS Conventions 2010, Section 5.4.1:
      # W = R3(-s') * R2(xp) * R1(yp)
      #
      # All elements use exact trigonometry — no small-angle approximation.
      #
      # @return [Array<Array<Float>>] 3x3 rotation matrix
      def rotation_matrix
        xp = x * ARCSEC_TO_RAD
        yp = y * ARCSEC_TO_RAD
        t = (mjd - TimeScale::MJD_J2000) / TimeScale::DAYS_PER_JULIAN_CENTURY
        sp = S_PRIME_RATE * t * ARCSEC_TO_RAD

        cx, sx = Math.cos(xp), Math.sin(xp)
        cy, sy = Math.cos(yp), Math.sin(yp)
        cs, ss = Math.cos(sp), Math.sin(sp)

        [
          [cx * cs, cx * ss, sx],
          [sy * sx * cs - cy * ss, cy * cs + sy * sx * ss, -sy * cx],
          [-sy * ss - cy * sx * cs, sy * cs - cy * sx * ss, cy * cx]
        ]
      end
    end

    extend EopParameter

    module_function

    # @param input [Time, Date, DateTime, nil]
    # @param jd [Float, nil] Julian Date
    # @param mjd [Float, nil] Modified Julian Date
    # @param interpolation [Symbol, nil] +:lagrange+ or +:linear+
    # @return [Entry]
    # @raise [OutOfRangeError]
    def at(input = nil, jd: nil, mjd: nil, interpolation: nil)
      query_mjd, window, method = resolve(
        input,
        jd: jd,
        mjd: mjd,
        interpolation: interpolation
      )

      x = interpolate_field(window, query_mjd, method) { |e| best_pm(e, :x) }
      y = interpolate_field(window, query_mjd, method) { |e| best_pm(e, :y) }

      Entry.new(
        x: x, y: y,
        mjd: query_mjd,
        data_quality: derive_quality(window, :pm_flag)
      )
    end

    # @param input [Time, Date, DateTime, nil]
    # @param jd [Float, nil] Julian Date
    # @param mjd [Float, nil] Modified Julian Date
    # @param interpolation [Symbol, nil] +:lagrange+ or +:linear+
    # @return [Array<Array<Float>>] 3x3 polar motion rotation matrix
    # @raise [OutOfRangeError]
    def rotation_matrix_at(input = nil, jd: nil, mjd: nil, interpolation: nil)
      at(input, jd: jd, mjd: mjd, interpolation: interpolation)
        .rotation_matrix
    end

    # @param start_date [Date]
    # @param end_date [Date]
    # @return [Enumerator::Lazy<Entry>]
    def between(start_date, end_date)
      start_mjd = TimeScale.to_mjd(start_date)
      end_mjd = TimeScale.to_mjd(end_date)
      entries = Data.finals_entries

      EopLookup
        .range(entries, start_mjd, end_mjd)
        .lazy
        .map do |e|
          Entry.new(
            x: best_pm(e, :x),
            y: best_pm(e, :y),
            mjd: e.mjd,
            data_quality: EopParameter::FLAG_TO_QUALITY.fetch(
              e.pm_flag, :observed
            )
          )
        end
    end

    def best_pm(entry, component)
      case component
      when :x
        entry.bulletin_b_pm_x || entry.pm_x
      when :y
        entry.bulletin_b_pm_y || entry.pm_y
      end
    end

    private_class_method :best_pm
  end
end
