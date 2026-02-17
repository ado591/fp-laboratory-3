defmodule InterpolationTest do
  use ExUnit.Case
  alias Interpolation.Algorithms
  alias Interpolation.PointParser

  describe "Algorithms.linear/2" do
    test "interpolates between two points" do
      points = [{0, 0}, {2, 4}]
      assert Algorithms.linear(1, points) == 2
    end

    test "works with unsorted points" do
      points = [{2, 4}, {0, 0}]
      assert Algorithms.linear(1, points) == 2
    end

    test "interpolates outside of the points" do
      points = [{1, 2}, {3, 6}]
      assert Algorithms.linear(4, points) == 8.0
    end
  end

  describe "Algorithms.newton/2" do
    test "computes Newton interpolation for 3 points" do
      points = [{0, 1}, {1, 3}, {2, 7}]
      y = Algorithms.newton(1.5, points)
      assert_in_delta y, 4.75, 0.001
    end

    test "works with two points (linear case)" do
      points = [{0, 0}, {2, 4}]
      y = Algorithms.newton(1, points)
      assert_in_delta y, 2, 0.001
    end
  end

  describe "Algorithms.finite_differences/1" do
    test "computes forward differences correctly" do
      points = [{0, 1}, {1, 4}, {2, 9}]
      diff_table = Algorithms.finite_differences(points)
      assert diff_table |> List.first() == [1, 4, 9]
      assert diff_table |> List.last() == [2]
    end
  end

  describe "PointParser.parse/1" do
    test "parses valid points" do
      assert PointParser.parse("1 2") == {:ok, {1.0, 2.0}}
      assert PointParser.parse("3;4") == {:ok, {3.0, 4.0}}
      assert PointParser.parse(" 5 \t 6 ") == {:ok, {5.0, 6.0}}
    end

    test "skips empty or invalid lines" do
      assert PointParser.parse("") == :skip
      assert PointParser.parse("abc def") == :skip
      assert PointParser.parse("1,2") == :skip
    end
  end

  describe "Calculate process" do
    test "linear algorithm sends results to printer" do
      printer = self()
      calc_pid = spawn(Interpolation.Calculate, :start, [[:linear], 1.0, 2, printer])

      send(calc_pid, {:data_point, {0, 0}})
      send(calc_pid, {:data_point, {2, 4}})

      result =
        receive do
          {:result, :linear, x, y} -> {x, y}
        after
          1000 -> :timeout
        end

      assert result == {0, 0} or result == {1, 2} or result == {2, 4}

      send(calc_pid, :eof)
    end

    test "newton algorithm sends results to printer" do
      printer = self()
      calc_pid = spawn(Interpolation.Calculate, :start, [[:newton], 1.0, 3, printer])

      send(calc_pid, {:data_point, {0, 1}})
      send(calc_pid, {:data_point, {1, 3}})
      send(calc_pid, {:data_point, {2, 7}})

      result =
        receive do
          {:result, :newton, x, y} -> {x, y}
        after
          1000 -> :timeout
        end

      assert elem(result, 1) in 1..7

      send(calc_pid, :eof)
    end
  end
end
