defmodule Interpolation.Algorithms do
  @moduledoc """
  Contains pure interpolation algorithms:
  - linear interpolation
  - Newton interpolation
  - finite differences table
  """
  def linear(x, points) do
    sorted = Enum.sort_by(points, fn {px, _} -> abs(px - x) end)

    [{x1, y1}, {x2, y2}] = Enum.take(sorted, 2)

    y = y1 + (y2 - y1) * (x - x1) / (x2 - x1)
    y
  end

  def newton(x, points) do
    n = length(points) - 1

    table =
      Enum.reduce(0..n, [], fn i, acc ->
        {_, y} = Enum.at(points, i)
        acc ++ [[y]]
      end)

    table =
      Enum.reduce(1..n, table, fn k, table_acc ->
        Enum.reduce(0..(n - k), table_acc, fn i, table_acc2 ->
          {xi, _} = Enum.at(points, i)
          {xik, _} = Enum.at(points, i + k)

          prev_i = Enum.at(Enum.at(table_acc2, i), k - 1)
          prev_j = Enum.at(Enum.at(table_acc2, i + 1), k - 1)

          diff = (prev_j - prev_i) / (xik - xi)

          row = Enum.at(table_acc2, i)
          List.update_at(table_acc2, i, fn _ -> row ++ [diff] end)
        end)
      end)

    result = Enum.at(Enum.at(table, 0), 0)

    {result, _} =
      Enum.reduce(1..n, {result, 1.0}, fn i, {res_acc, prod_acc} ->
        {xi, _} = Enum.at(points, i - 1)
        product = prod_acc * (x - xi)
        diff = Enum.at(Enum.at(table, 0), i)
        {res_acc + diff * product, product}
      end)

    result
  end

  def finite_differences(points) do
    n = length(points) - 1
    y_vals = Enum.map(points, fn {_, y} -> y end)

    Enum.reduce(1..n, [y_vals], fn _, [current | _] = acc ->
      new_row =
        Enum.reduce(0..(length(current) - 2), [], fn i, row_acc ->
          diff = Enum.at(current, i + 1) - Enum.at(current, i)
          row_acc ++ [diff]
        end)

      [new_row | acc]
    end)
    |> Enum.reverse()
  end
end
