# frozen_string_literal: true

require "test_helper"
require_relative "../support/reference_comparison"

class TestInterpF < Minitest::Test
  include ReferenceComparison

  FIXTURE = ReferenceComparison.load_reference("interp_f")
  MICRO = 1e6

  def test_the_fixture_lists_cases
    refute_empty FIXTURE["cases"]
  end

  def test_the_default_interpolation_matches_lagint
    results = differences { |c| c["lagint"] }

    results.each do |quantity, values|
      assert_differences_within(
        values,
        max: 1e-6, rms: 1e-6,
        label: "#{quantity} against LAGINT",
        unit: (quantity == :ut1_utc) ? "us" : "uas"
      )
    end
  end

  def test_leaving_out_the_sub_daily_corrections_costs_under_a_milliarcsecond
    results = differences do |c|
      x, y, ut1_utc = c["lagint"]
      ox, oy, out1 = c["ocean_tides"]
      lx, ly = c["libration"]
      [x + ox + lx, y + oy + ly, ut1_utc + out1]
    end

    {ut1_utc: [90, 30], x: [900, 350], y: [750, 270]}
      .each do |quantity, (max, rms)|
        assert_differences_within(
          results.fetch(quantity),
          max: max, rms: rms,
          label: "#{quantity} against interp.f",
          unit: (quantity == :ut1_utc) ? "us" : "uas"
        )
      end
  end

  private

  def differences
    with_finals(FIXTURE["c04_0h"], lagrange_order: 4) do
      results = {ut1_utc: [], x: [], y: []}

      FIXTURE["cases"].each do |reference|
        mjd = reference["mjd"]
        x, y, ut1_utc = yield reference
        pm = IERS::PolarMotion.at(mjd: mjd, interpolation: :lagrange)
        ut1 = IERS::UT1.at(mjd: mjd, interpolation: :lagrange)

        results[:x] << (pm.x - x) * MICRO
        results[:y] << (pm.y - y) * MICRO
        results[:ut1_utc] << (ut1.ut1_utc - ut1_utc) * MICRO
      end

      results
    end
  end
end
