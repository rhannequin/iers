# frozen_string_literal: true

require "test_helper"
require_relative "../support/reference_comparison"

class TestCdtEra < Minitest::Test
  include ReferenceComparison

  FIXTURE = ReferenceComparison.load_reference("cdt_era")
  RAD_TO_ARCSEC = 648_000.0 / Math::PI
  TURN = 1_296_000.0

  def test_the_fixture_lists_every_day_of_the_year
    assert_equal 368, FIXTURE["cases"].size
  end

  def test_earth_rotation_angle_matches_the_connaissance_des_temps
    first, last = FIXTURE["cases"].values_at(0, -1).map { |c| c["mjd"] }
    rows = (first - 5).step(last + 5).map { |mjd| [mjd, 0.0, 0.0, 0.0] }

    differences = with_finals(rows) do
      FIXTURE["cases"].map do |reference|
        degrees, minutes, seconds = reference["era"]
        expected = degrees * 3600 + minutes * 60 + seconds
        actual =
          IERS::EarthRotationAngle.at(mjd: reference["mjd"]) * RAD_TO_ARCSEC

        ((actual - expected + TURN / 2) % TURN - TURN / 2) * 1e6
      end
    end

    assert_differences_within(
      differences, max: 15, rms: 8, label: "ERA against the CDT", unit: "uas"
    )
  end
end
