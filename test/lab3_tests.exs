defmodule Interpolation.InterpolationTest do
  use ExUnit.Case, async: true

  @points [{0.0, 0.0}, {1.0, 1.0}, {2.0, 4.0}, {3.0, 9.0}]

  test "linear interpolation between nearest neighbours" do
    assert Interpolation.Algorithms.linear(@points, 0.5) == 0.5
    assert Interpolation.Algorithms.linear(@points, 1.5) == 2.5
    assert Interpolation.Algorithms.linear(@points, -1.0) == nil
  end

  test "newton interpolation uses window of closest points" do
    assert_in_delta Interpolation.Algorithms.newton(@points, 1.5, 3), 2.25, 1.0e-6
    assert_in_delta Interpolation.Algorithms.newton(@points, 2.5, 3), 6.25, 1.0e-6
  end
end