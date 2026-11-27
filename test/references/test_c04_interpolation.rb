# frozen_string_literal: true

require "test_helper"
require_relative "../support/reference_comparison"

class TestC04Interpolation < Minitest::Test
  include ReferenceComparison

  FIXTURE = ReferenceComparison.load_reference("c04_interpolation")
  MICRO = 1e6
  ITRF2020_POLE_FROM_MJD = 49_353.0

  TOLERANCES = {
    linear: {ut1_utc: [50, 20], x: [200, 60], y: [200, 60]},
    lagrange_4: {ut1_utc: [60, 6], x: [120, 35], y: [120, 35]},
    lagrange_6: {ut1_utc: [100, 7], x: [100, 30], y: [100, 30]},
    lagrange_8: {ut1_utc: [120, 8], x: [100, 30], y: [100, 30]}
  }.freeze

  def test_the_fixture_lists_cases_and_their_daily_values
    refute_empty FIXTURE["cases"]
    assert_operator FIXTURE["c04_0h"].size, :>=, FIXTURE["cases"].size * 4
  end

  def test_linear_interpolation_against_c04_at_noon
    assert_interpolation_within(:linear, nil)
  end

  def test_lagrange_order_4_interpolation_against_c04_at_noon
    assert_interpolation_within(:lagrange, 4)
  end

  def test_lagrange_order_6_interpolation_against_c04_at_noon
    assert_interpolation_within(:lagrange, 6)
  end

  def test_lagrange_order_8_interpolation_against_c04_at_noon
    assert_interpolation_within(:lagrange, 8)
  end

  def test_the_default_lagrange_beats_linear_on_ut1
    linear = summarize(differences(:linear, nil)[:ut1_utc])
    lagrange = summarize(differences(:lagrange, 4)[:ut1_utc])

    assert_operator lagrange[:rms], :<, linear[:rms] / 2
  end

  def test_the_noons_around_leap_seconds_stay_within_the_ut1_tolerance
    leap_cases = FIXTURE["cases"].select do |mjd, *|
      ReferenceComparison::LEAP_SECOND_MJDS.any? { |l| (mjd - l).abs < 1 }
    end

    refute_empty leap_cases

    with_finals(FIXTURE["c04_0h"]) do
      leap_cases.each do |mjd, _x, _y, ut1_utc|
        actual = IERS::UT1.at(mjd: mjd).ut1_utc

        assert_in_delta ut1_utc, actual, 60e-6, "UT1-UTC at MJD #{mjd}"
      end
    end
  end

  private

  def assert_interpolation_within(interpolation, order)
    name = order ? :"#{interpolation}_#{order}" : interpolation
    results = differences(interpolation, order)

    TOLERANCES.fetch(name).each do |quantity, (max, rms)|
      assert_differences_within(
        results.fetch(quantity),
        max: max, rms: rms,
        label: "#{name} #{quantity}",
        unit: (quantity == :ut1_utc) ? "us" : "uas"
      )
    end
  end

  def differences(interpolation, order)
    with_finals(FIXTURE["c04_0h"], lagrange_order: order) do
      results = {ut1_utc: [], x: [], y: []}

      FIXTURE["cases"].each do |mjd, x, y, ut1_utc|
        ut1 = IERS::UT1.at(mjd: mjd, interpolation: interpolation)
        results[:ut1_utc] << (ut1.ut1_utc - ut1_utc) * MICRO
        next if mjd < ITRF2020_POLE_FROM_MJD

        pm = IERS::PolarMotion.at(mjd: mjd, interpolation: interpolation)
        results[:x] << (pm.x - x) * MICRO
        results[:y] << (pm.y - y) * MICRO
      end

      results
    end
  end
end
