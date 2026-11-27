# frozen_string_literal: true

require "test_helper"
require_relative "../support/reference_comparison"

class TestErfaRotation < Minitest::Test
  include ReferenceComparison

  FIXTURE = ReferenceComparison.load_reference("erfa_rotation")
  RAD_TO_UAS = 648_000.0e6 / Math::PI
  CONSTANT_DAYS = (-5..5)

  def test_the_fixture_lists_cases
    refute_empty FIXTURE["cases"]
  end

  def test_the_gem_reads_the_same_tai_utc_as_erfa
    each_case do |reference|
      assert_equal reference["tai_utc"],
        IERS::LeapSecond.at(mjd: reference["mjd"]).to_f
    end
  end

  def test_the_gem_hands_each_case_its_own_ut1_utc_and_pole
    each_case do |reference|
      mjd = reference["mjd"]
      pm = IERS::PolarMotion.at(mjd: mjd)

      assert_in_delta reference["ut1_utc"], IERS::UT1.at(mjd: mjd).ut1_utc, 1e-12
      assert_in_delta reference["x"], pm.x, 1e-12
      assert_in_delta reference["y"], pm.y, 1e-12
    end
  end

  def test_earth_rotation_angle_matches_era00
    differences = collect do |reference|
      angle_difference(
        IERS::EarthRotationAngle.at(mjd: reference["mjd"]),
        reference["era00"]
      )
    end

    assert_differences_within(
      differences, max: 10, rms: 4, label: "ERA against era00", unit: "uas"
    )
  end

  def test_gmst_matches_gmst06
    differences = collect do |reference|
      angle_difference(IERS::GMST.at(mjd: reference["mjd"]), reference["gmst06"])
    end

    assert_differences_within(
      differences, max: 10, rms: 4, label: "GMST against gmst06", unit: "uas"
    )
  end

  def test_polar_motion_matrix_matches_pom00_including_s_prime
    differences = collect do |reference|
      matrix_difference(
        IERS::PolarMotion.rotation_matrix_at(mjd: reference["mjd"]),
        reference["pom00"]
      )
    end

    assert_differences_within(
      differences, max: 1e-4, rms: 1e-4, label: "W against pom00", unit: "uas"
    )
  end

  def test_terrestrial_rotation_matches_c2tcio
    differences = collect do |reference|
      matrix_difference(
        IERS::TerrestrialRotation.at(mjd: reference["mjd"]),
        reference["c2tcio"]
      )
    end

    assert_differences_within(
      differences,
      max: 10, rms: 4,
      label: "TerrestrialRotation against c2tcio",
      unit: "uas"
    )
  end

  private

  def each_case(&block)
    rows = FIXTURE["cases"].flat_map do |reference|
      day = reference["mjd"].floor
      CONSTANT_DAYS.map do |offset|
        [day + offset, reference["x"], reference["y"], reference["ut1_utc"]]
      end
    end

    with_finals(rows) { FIXTURE["cases"].each(&block) }
  end

  def collect
    differences = []
    each_case { |reference| differences << yield(reference) }
    differences
  end

  def angle_difference(actual, expected)
    ((actual - expected + Math::PI) % (2 * Math::PI) - Math::PI) * RAD_TO_UAS
  end

  def matrix_difference(actual, expected)
    actual.flatten.zip(expected.flatten).map { |a, e| (a - e).abs }.max *
      RAD_TO_UAS
  end
end
