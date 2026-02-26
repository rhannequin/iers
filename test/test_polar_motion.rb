# frozen_string_literal: true

require "test_helper"

class TestPolarMotionEntry < Minitest::Test
  def test_has_x
    entry = IERS::PolarMotion::Entry.new(
      x: 0.143,
      y: 0.137,
      mjd: 41684.0,
      data_quality: :observed
    )

    assert_in_delta 0.143, entry.x
  end

  def test_has_y
    entry = IERS::PolarMotion::Entry.new(
      x: 0.143,
      y: 0.137,
      mjd: 41684.0,
      data_quality: :observed
    )

    assert_in_delta 0.137, entry.y
  end

  def test_has_mjd
    entry = IERS::PolarMotion::Entry.new(
      x: 0.143,
      y: 0.137,
      mjd: 41684.0,
      data_quality: :observed
    )

    assert_in_delta 41684.0, entry.mjd
  end

  def test_has_data_quality
    entry = IERS::PolarMotion::Entry.new(
      x: 0.143,
      y: 0.137,
      mjd: 41684.0,
      data_quality: :observed
    )

    assert_equal :observed, entry.data_quality
  end

  def test_observed_predicate
    entry = IERS::PolarMotion::Entry.new(
      x: 0.143,
      y: 0.137,
      mjd: 41684.0,
      data_quality: :observed
    )

    assert_predicate entry, :observed?
  end

  def test_predicted_predicate
    entry = IERS::PolarMotion::Entry.new(
      x: 0.143,
      y: 0.137,
      mjd: 41684.0,
      data_quality: :predicted
    )

    assert_predicate entry, :predicted?
  end

  def test_date_returns_date
    entry = IERS::PolarMotion::Entry.new(
      x: 0.143,
      y: 0.137,
      mjd: 41684.0,
      data_quality: :observed
    )

    assert_equal Date.new(1973, 1, 2), entry.date
  end

  def test_is_frozen
    entry = IERS::PolarMotion::Entry.new(
      x: 0.143,
      y: 0.137,
      mjd: 41684.0,
      data_quality: :observed
    )

    assert_predicate entry, :frozen?
  end
end

class TestPolarMotionAt < Minitest::Test
  def setup
    IERS.configure do |config|
      config.finals_path = fixture_path("finals_10_days.dat")
      config.leap_second_path = fixture_path(
        "leap_second_query.dat"
      )
    end
  end

  def teardown
    IERS.reset_configuration!
  end

  def fixture_path(name)
    Pathname(__dir__).join("fixtures", name)
  end

  def test_returns_entry_instance
    result = IERS::PolarMotion.at(mjd: 41687.5)

    assert_instance_of IERS::PolarMotion::Entry, result
  end

  def test_entry_x_is_float
    result = IERS::PolarMotion.at(mjd: 41687.5)

    assert_instance_of Float, result.x
  end

  def test_entry_y_is_float
    result = IERS::PolarMotion.at(mjd: 41687.5)

    assert_instance_of Float, result.y
  end

  def test_entry_has_query_mjd
    result = IERS::PolarMotion.at(mjd: 41687.5)

    assert_in_delta 41687.5, result.mjd
  end

  def test_on_exact_grid_point_prefers_bulletin_b_x
    result = IERS::PolarMotion.at(mjd: 41684.0)

    assert_in_delta 0.143, result.x, 1e-4
  end

  def test_on_exact_grid_point_prefers_bulletin_b_y
    result = IERS::PolarMotion.at(mjd: 41684.0)

    assert_in_delta 0.137, result.y, 1e-4
  end

  def test_between_grid_points_x
    result = IERS::PolarMotion.at(mjd: 41687.5)

    assert_in_delta 0.136, result.x, 1e-3
  end

  def test_between_grid_points_y
    result = IERS::PolarMotion.at(mjd: 41687.5)

    assert_in_delta 0.1265, result.y, 1e-3
  end

  def test_with_time_object
    result = IERS::PolarMotion.at(Time.utc(1973, 1, 5))

    assert_in_delta 0.137, result.x, 1e-3
  end

  def test_with_date_object
    result = IERS::PolarMotion.at(Date.new(1973, 1, 5))

    assert_in_delta 0.128, result.y, 1e-3
  end

  def test_before_data_raises_out_of_range_error
    error = assert_raises(IERS::OutOfRangeError) do
      IERS::PolarMotion.at(mjd: 41683.0)
    end

    assert_in_delta 41683.0, error.requested_mjd
    assert_equal 41684.0..41693.0, error.available_range
  end

  def test_after_data_raises_out_of_range_error
    assert_raises(IERS::OutOfRangeError) do
      IERS::PolarMotion.at(mjd: 41694.0)
    end
  end
end

class TestPolarMotionDataQuality < Minitest::Test
  def setup
    IERS.configure do |config|
      config.finals_path = fixture_path("finals_mixed_ip.dat")
      config.leap_second_path = fixture_path(
        "leap_second_query.dat"
      )
    end
  end

  def teardown
    IERS.reset_configuration!
  end

  def fixture_path(name)
    Pathname(__dir__).join("fixtures", name)
  end

  def test_observed_data_is_observed
    result = IERS::PolarMotion.at(mjd: 41685.5)

    assert_predicate result, :observed?
  end

  def test_predicted_data_is_predicted
    result = IERS::PolarMotion.at(mjd: 41688.5)

    assert_predicate result, :predicted?
  end

  def test_crossing_boundary_is_predicted
    result = IERS::PolarMotion.at(mjd: 41687.5)

    assert_predicate result, :predicted?
  end

  def test_observed_uses_bulletin_b_x
    result = IERS::PolarMotion.at(mjd: 41684.0)

    assert_in_delta 0.143, result.x, 1e-4
  end

  def test_predicted_falls_back_to_series_a
    result = IERS::PolarMotion.at(mjd: 41688.0)

    assert_in_delta 0.113721, result.x, 1e-4
  end
end

class TestPolarMotionBetween < Minitest::Test
  def setup
    IERS.configure do |config|
      config.finals_path = fixture_path("finals_10_days.dat")
      config.leap_second_path = fixture_path(
        "leap_second_query.dat"
      )
    end
  end

  def teardown
    IERS.reset_configuration!
  end

  def fixture_path(name)
    Pathname(__dir__).join("fixtures", name)
  end

  def test_returns_array_of_entries
    results = IERS::PolarMotion.between(
      Date.new(1973, 1, 3),
      Date.new(1973, 1, 5)
    )

    assert_instance_of IERS::PolarMotion::Entry,
      results.first
  end

  def test_correct_count_for_date_range
    results = IERS::PolarMotion.between(
      Date.new(1973, 1, 3),
      Date.new(1973, 1, 7)
    )

    assert_equal 5, results.size
  end

  def test_first_entry_mjd
    results = IERS::PolarMotion.between(
      Date.new(1973, 1, 3),
      Date.new(1973, 1, 7)
    )

    assert_in_delta 41685.0, results.first.mjd
  end

  def test_last_entry_mjd
    results = IERS::PolarMotion.between(
      Date.new(1973, 1, 3),
      Date.new(1973, 1, 7)
    )

    assert_in_delta 41689.0, results.last.mjd
  end

  def test_entries_have_x_and_y
    results = IERS::PolarMotion.between(
      Date.new(1973, 1, 3),
      Date.new(1973, 1, 5)
    )

    assert_instance_of Float, results.first.x
    assert_instance_of Float, results.first.y
  end

  def test_entries_have_data_quality
    results = IERS::PolarMotion.between(
      Date.new(1973, 1, 3),
      Date.new(1973, 1, 5)
    )

    assert_equal :observed, results.first.data_quality
  end

  def test_empty_array_for_out_of_data_range
    results = IERS::PolarMotion.between(
      Date.new(1980, 1, 1),
      Date.new(1980, 1, 5)
    )

    assert_empty results
  end

  def test_single_day_range
    results = IERS::PolarMotion.between(
      Date.new(1973, 1, 5),
      Date.new(1973, 1, 5)
    )

    assert_equal 1, results.size
  end

  def test_returns_frozen_array
    results = IERS::PolarMotion.between(
      Date.new(1973, 1, 3),
      Date.new(1973, 1, 5)
    )

    assert_predicate results, :frozen?
  end

  def test_between_uses_bulletin_b
    results = IERS::PolarMotion.between(
      Date.new(1973, 1, 2),
      Date.new(1973, 1, 2)
    )

    assert_in_delta 0.143, results.first.x, 1e-4
    assert_in_delta 0.137, results.first.y, 1e-4
  end
end

class TestPolarMotionInterpolationOverride < Minitest::Test
  def setup
    IERS.configure do |config|
      config.finals_path = fixture_path("finals_10_days.dat")
      config.leap_second_path = fixture_path(
        "leap_second_query.dat"
      )
    end
  end

  def teardown
    IERS.reset_configuration!
  end

  def fixture_path(name)
    Pathname(__dir__).join("fixtures", name)
  end

  def test_linear_override_returns_entry
    result = IERS::PolarMotion.at(
      mjd: 41687.5,
      interpolation: :linear
    )

    assert_instance_of IERS::PolarMotion::Entry, result
  end

  def test_linear_at_midpoint_x_equals_average
    # MJD 41687 bb_pm_x=0.137, MJD 41688 bb_pm_x=0.135
    expected = (0.137 + 0.135) / 2.0
    result = IERS::PolarMotion.at(
      mjd: 41687.5,
      interpolation: :linear
    )

    assert_in_delta expected, result.x, 1e-6
  end

  def test_linear_at_midpoint_y_equals_average
    # MJD 41687 bb_pm_y=0.128, MJD 41688 bb_pm_y=0.125
    expected = (0.128 + 0.125) / 2.0
    result = IERS::PolarMotion.at(
      mjd: 41687.5,
      interpolation: :linear
    )

    assert_in_delta expected, result.y, 1e-6
  end

  def test_override_does_not_mutate_global_config
    IERS::PolarMotion.at(
      mjd: 41687.5,
      interpolation: :linear
    )

    assert_equal :lagrange,
      IERS.configuration.interpolation
  end
end

class TestPolarMotionEntryRotationMatrix < Minitest::Test
  ARCSEC_TO_RAD = Math::PI / 648_000.0

  def test_returns_nested_array
    entry = IERS::PolarMotion::Entry.new(
      x: 0.143, y: 0.137, mjd: 41684.0, data_quality: :observed
    )

    assert_instance_of Array, entry.rotation_matrix
  end

  def test_dimensions
    entry = IERS::PolarMotion::Entry.new(
      x: 0.143, y: 0.137, mjd: 41684.0, data_quality: :observed
    )
    w = entry.rotation_matrix

    assert_equal 3, w.length
    w.each { |row| assert_equal 3, row.length }
  end

  def test_diagonal_near_unity
    entry = IERS::PolarMotion::Entry.new(
      x: 0.143, y: 0.137, mjd: 41684.0, data_quality: :observed
    )
    w = entry.rotation_matrix

    assert_in_delta 1.0, w[0][0], 1e-10
    assert_in_delta 1.0, w[1][1], 1e-10
    assert_in_delta 1.0, w[2][2], 1e-10
  end

  def test_w20_approximates_negative_xp_rad
    entry = IERS::PolarMotion::Entry.new(
      x: 0.143, y: 0.137, mjd: 41684.0, data_quality: :observed
    )
    xp_rad = 0.143 * ARCSEC_TO_RAD

    assert_in_delta(-xp_rad, entry.rotation_matrix[2][0], 1e-12)
  end

  def test_w21_approximates_yp_rad
    entry = IERS::PolarMotion::Entry.new(
      x: 0.143, y: 0.137, mjd: 41684.0, data_quality: :observed
    )
    yp_rad = 0.137 * ARCSEC_TO_RAD

    assert_in_delta yp_rad, entry.rotation_matrix[2][1], 1e-12
  end

  def test_orthogonality
    entry = IERS::PolarMotion::Entry.new(
      x: 0.143, y: 0.137, mjd: 41684.0, data_quality: :observed
    )
    w = entry.rotation_matrix
    wt = w.transpose
    product = Array.new(3) { |i|
      Array.new(3) { |j| wt[i].zip(w.map { |r| r[j] }).sum { |a, b| a * b } }
    }

    3.times do |i|
      3.times do |j|
        expected = (i == j) ? 1.0 : 0.0

        assert_in_delta expected, product[i][j], 1e-12,
          "W^T * W [#{i},#{j}] should be #{expected}"
      end
    end
  end
end

class TestPolarMotionRotationMatrixAt < Minitest::Test
  def setup
    IERS.configure do |config|
      config.finals_path = fixture_path("finals_10_days.dat")
      config.leap_second_path = fixture_path(
        "leap_second_query.dat"
      )
    end
  end

  def teardown
    IERS.reset_configuration!
  end

  def fixture_path(name)
    Pathname(__dir__).join("fixtures", name)
  end

  def test_returns_nested_array
    result = IERS::PolarMotion.rotation_matrix_at(mjd: 41684.0)

    assert_instance_of Array, result
  end

  def test_matches_entry_rotation_matrix
    entry = IERS::PolarMotion.at(mjd: 41684.0)
    direct = IERS::PolarMotion.rotation_matrix_at(mjd: 41684.0)

    assert_equal entry.rotation_matrix, direct
  end

  def test_accepts_jd_keyword
    result = IERS::PolarMotion.rotation_matrix_at(
      jd: 41684.0 + 2_400_000.5
    )

    assert_instance_of Array, result
  end

  def test_accepts_time_object
    result = IERS::PolarMotion.rotation_matrix_at(
      Time.utc(1973, 1, 2)
    )

    assert_instance_of Array, result
  end
end
