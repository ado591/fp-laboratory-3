defmodule Interpolation do
  @moduledoc """
  main entry point for interpolating data from input streams using command-line arguments.
  """

  alias Interpolation.{Options, StreamProcessor}

  def run(argv, input_stream \\ IO.stream(:stdio, :line), output_fun \\ &IO.puts/1) do
    argv
    |> Options.parse()
    |> StreamProcessor.run(input_stream, output_fun)
  end
end