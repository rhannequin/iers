# frozen_string_literal: true

require "test_helper"

class TestLinearInterpolation < Minitest::Test
  def test_at_left_boundary
    assert_in_delta 0.0,
      IERS::Interpolation.linear([0.0, 1.0], [0.0, 10.0], 0.0)
  end

  def test_at_right_boundary
    assert_in_delta 10.0,
      IERS::Interpolation.linear([0.0, 1.0], [0.0, 10.0], 1.0)
  end

  def test_at_midpoint
    assert_in_delta 5.0,
      IERS::Interpolation.linear([0.0, 1.0], [0.0, 10.0], 0.5)
  end

  def test_at_quarter_point
    assert_in_delta 2.5,
      IERS::Interpolation.linear([0.0, 1.0], [0.0, 10.0], 0.25)
  end

  def test_with_negative_values
    assert_in_delta(-5.0,
      IERS::Interpolation.linear([0.0, 1.0], [-10.0, 0.0], 0.5))
  end

  def test_returns_float
    assert_instance_of Float,
      IERS::Interpolation.linear([0.0, 1.0], [0.0, 10.0], 0.5)
  end

  def test_requires_exactly_two_points
    assert_raises(ArgumentError) do
      IERS::Interpolation.linear([0.0, 1.0, 2.0], [0.0, 10.0, 20.0], 0.5)
    end
  end
end
