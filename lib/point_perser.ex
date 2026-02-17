defmodule Interpolation.PointParser do
  @moduledoc """
  Reads input points from standard input
  and sends them to the calculation process.
  """

  @type point :: {float(), float()}

  @spec parse(String.t()) :: {:ok, point} | :skip
  def parse(line) do
    trimmed = String.trim(line)

    case trimmed do
      "" -> :skip
      _ -> parse_pair(trimmed)
    end
  end

  defp parse_pair(line) do
    case String.split(line, ~r/[\s;]+/, trim: true) do
      [xs, ys] ->
        with {x, ""} <- Float.parse(xs),
             {y, ""} <- Float.parse(ys) do
          {:ok, {x, y}}
        else
          _ -> :skip
        end

      _ ->
        :skip
    end
  end
end
