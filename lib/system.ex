defmodule Interpolation.System do
  @moduledoc """
  Application entry point.
  Parses CLI arguments and starts system processes.
  """
  def main(args) do
    {opts, _, _} =
      OptionParser.parse(args,
        switches: [
          linear: :boolean,
          newton: :boolean,
          step: :float,
          window: :integer,
          help: :boolean
        ],
        aliases: [l: :linear, n: :newton, s: :step, w: :window, h: :help]
      )

    if opts[:help] do
      IO.puts("mix run -- --linear --step 0.5")
      System.halt(0)
    end

    algs = []
    algs = if opts[:linear], do: [:linear | algs], else: algs
    algs = if opts[:newton], do: [:newton | algs], else: algs

    if algs == [] do
      IO.puts("Алгоритм не выбран")
      System.halt(1)
    end

    step = opts[:step] || 0.5
    window = opts[:window] || 4

    printer = spawn(Interpolation.Printer, :start, [])
    calc = spawn(Interpolation.Calculate, :start, [algs, step, window, printer])
    reader = spawn(Interpolation.Reader, :start_reader, [calc])

    Process.monitor(reader)

    receive do
      {:DOWN, _, _, _, _} -> :ok
    end
  end
end
