# frozen_string_literal: true

module IERS
  module TerrestrialRotation
    module_function

    # Compute R(ERA) × W, the rotation from ITRS to TIRS
    # (IERS Conventions 2010, eq. 5.1), combining the Earth Rotation
    # Angle and polar motion matrices.
    #
    # @param input [Time, Date, DateTime, nil]
    # @param jd [Float, nil] Julian Date
    # @param mjd [Float, nil] Modified Julian Date
    # @param interpolation [Symbol, nil] +:lagrange+ or +:linear+
    # @return [Array<Array<Float>>] 3×3 rotation matrix (row-major)
    # @raise [OutOfRangeError]
    def at(input = nil, jd: nil, mjd: nil, interpolation: nil)
      query_mjd = TimeScale.to_mjd(input, jd: jd, mjd: mjd)
      era = EarthRotationAngle.at(mjd: query_mjd, interpolation: interpolation)
      w = PolarMotion.rotation_matrix_at(
        mjd: query_mjd, interpolation: interpolation
      )

      multiply(r3_matrix(era), w)
    end

    def r3_matrix(angle)
      c = Math.cos(angle)
      s = Math.sin(angle)

      [
        [c, s, 0.0],
        [-s, c, 0.0],
        [0.0, 0.0, 1.0]
      ]
    end

    def multiply(a, b)
      Array.new(3) { |i|
        Array.new(3) { |j|
          a[i].zip(b.map { |r| r[j] }).sum { |x, y| x * y }
        }
      }
    end

    private_class_method :r3_matrix, :multiply
  end
end
