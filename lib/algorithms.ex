defmodule Interpolation.Algorithms do
  @moduledoc """
  Linear and Newton algorithms implementation
  """
  def linear(points, x) do
    points
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.find_value(fn [{x1, y1}, {x2, y2}] ->
      if x >= x1 and x <= x2 do
        t = (x - x1) / (x2 - x1)
        y1 + t * (y2 - y1)
      end
    end)
  end

  def newton(points, _x, _window) when length(points) < 2, do: nil

  def newton(points, x, window) do
    pts =
      points
      |> Enum.sort_by(fn {xi, _yi} -> abs(xi - x) end)
      |> Enum.take(window)
      |> Enum.sort_by(fn {xi, _yi} -> xi end)

    xs = Enum.map(pts, &elem(&1, 0))
    ys = Enum.map(pts, &elem(&1, 1))

    divided_differences(xs, ys)
    |> evaluate(xs, x)
  end

  defp divided_differences(xs, ys) do
    n = length(xs)
    level0 = ys

    Enum.reduce(1..(n - 1), [level0], fn level, acc ->
      prev = List.last(acc)

      curr =
        0..(n - level - 1)
        |> Enum.map(fn i ->
          num = Enum.at(prev, i + 1) - Enum.at(prev, i)
          den = Enum.at(xs, i + level) - Enum.at(xs, i)
          num / den
        end)

      acc ++ [curr]
    end)
  end

  defp evaluate(deltas, xs, x) do
    n = length(xs)
    base = hd(deltas)

    Enum.reduce(1..(n - 1), hd(base), fn i, acc ->
      coeff = deltas |> Enum.at(i) |> hd()

      prod =
        xs
        |> Enum.take(i)
        |> Enum.reduce(1.0, fn xk, p -> p * (x - xk) end)

      acc + coeff * prod
    end)
  end

end