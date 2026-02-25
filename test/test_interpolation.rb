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

class TestLagrangeInterpolation < Minitest::Test
  def test_two_points_matches_linear
    xs = [0.0, 1.0]
    ys = [0.0, 10.0]

    assert_in_delta IERS::Interpolation.linear(xs, ys, 0.5),
      IERS::Interpolation.lagrange(xs, ys, 0.5)
  end

  def test_at_node_returns_exact_value
    xs = [1.0, 2.0, 3.0, 4.0]
    ys = [10.0, 20.0, 30.0, 40.0]

    assert_in_delta 20.0, IERS::Interpolation.lagrange(xs, ys, 2.0)
  end

  def test_order_4_reproduces_quadratic
    xs = [1.0, 2.0, 3.0, 4.0]
    ys = xs.map { |x| x**2 }

    assert_in_delta 6.25, IERS::Interpolation.lagrange(xs, ys, 2.5)
  end

  def test_order_4_reproduces_cubic
    xs = [1.0, 2.0, 3.0, 4.0]
    ys = xs.map { |x| x**3 }

    assert_in_delta 15.625, IERS::Interpolation.lagrange(xs, ys, 2.5)
  end

  def test_with_negative_y_values
    xs = [0.0, 1.0, 2.0]
    ys = [-5.0, 0.0, -5.0]

    assert_in_delta(-5.0,
      IERS::Interpolation.lagrange(xs, ys, 0.0))
  end

  def test_returns_float
    xs = [1.0, 2.0, 3.0]
    ys = [1.0, 4.0, 9.0]

    assert_instance_of Float,
      IERS::Interpolation.lagrange(xs, ys, 1.5)
  end

  def test_requires_matching_array_sizes
    assert_raises(ArgumentError) do
      IERS::Interpolation.lagrange([1.0, 2.0], [1.0], 1.5)
    end
  end

  def test_requires_at_least_two_points
    assert_raises(ArgumentError) do
      IERS::Interpolation.lagrange([1.0], [1.0], 1.0)
    end
  end
end
