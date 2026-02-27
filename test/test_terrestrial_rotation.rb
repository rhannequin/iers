# frozen_string_literal: true

require "test_helper"

class TestTerrestrialRotationAt < Minitest::Test
  def setup
    IERS.configure do |config|
      config.finals_path = fixture_path("finals_10_days.dat")
      config.leap_second_path = fixture_path("leap_second_query.dat")
    end
  end

  def teardown
    IERS.reset_configuration!
  end

  def fixture_path(name)
    Pathname(__dir__).join("fixtures", name)
  end

  def test_returns_nested_array
    r = IERS::TerrestrialRotation.at(mjd: 41687.0)

    assert_instance_of Array, r
    r.each { |row| assert_instance_of Array, row }
  end

  def test_dimensions
    r = IERS::TerrestrialRotation.at(mjd: 41687.0)

    assert_equal 3, r.length
    r.each { |row| assert_equal 3, row.length }
  end

  def test_orthogonality
    r = IERS::TerrestrialRotation.at(mjd: 41687.0)
    rt = r.transpose
    product = Array.new(3) { |i|
      Array.new(3) { |j|
        rt[i]
          .zip(r.map { |row| row[j] })
          .sum { |a, b| a * b }
      }
    }

    3.times do |i|
      3.times do |j|
        expected = (i == j) ? 1.0 : 0.0

        assert_in_delta expected, product[i][j], 1e-12,
          "R^T * R [#{i},#{j}] should be #{expected}"
      end
    end
  end

  def test_determinant_is_one
    r = IERS::TerrestrialRotation.at(mjd: 41687.0)

    det = r[0][0] * (r[1][1] * r[2][2] - r[1][2] * r[2][1]) -
      r[0][1] * (r[1][0] * r[2][2] - r[1][2] * r[2][0]) +
      r[0][2] * (r[1][0] * r[2][1] - r[1][1] * r[2][0])

    assert_in_delta 1.0, det, 1e-12
  end

  def test_consistent_with_manual_multiplication
    query_mjd = 41687.0
    era = IERS::EarthRotationAngle.at(mjd: query_mjd)
    w = IERS::PolarMotion.rotation_matrix_at(mjd: query_mjd)

    c = Math.cos(era)
    s = Math.sin(era)
    r3 = [[c, s, 0.0], [-s, c, 0.0], [0.0, 0.0, 1.0]]

    expected = Array.new(3) { |i|
      Array.new(3) { |j|
        r3[i].zip(w.map { |row| row[j] }).sum { |a, b| a * b }
      }
    }

    r = IERS::TerrestrialRotation.at(mjd: query_mjd)

    3.times do |i|
      3.times do |j|
        assert_in_delta expected[i][j], r[i][j], 1e-15,
          "element [#{i},#{j}] should match manual computation"
      end
    end
  end

  def test_accepts_interpolation_keyword
    r = IERS::TerrestrialRotation.at(mjd: 41687.0, interpolation: :linear)

    assert_equal 3, r.length
  end

  def test_before_data_raises_out_of_range_error
    assert_raises(IERS::OutOfRangeError) do
      IERS::TerrestrialRotation.at(mjd: 41683.0)
    end
  end
end
