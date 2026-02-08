defmodule Interpolation.System do
  @moduledoc """
  reading stdin line-by-line and writing results to stdout
  """

  alias Interpolation.{Options, StreamProcessor}

  @spec main([String.t()]) :: :ok
  def main(argv) do
    argv
    |> Options.parse()
    |> StreamProcessor.run(IO.stream(:stdio, :line), &IO.puts/1)
  end
end