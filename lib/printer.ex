defmodule Interpolation.Printer do
  @moduledoc """
  Receives calculated interpolation results
  and prints them to standard output.
  """
  def start do
    loop()
  end

  defp loop do
    receive do
      {:result, algorithm, x, y} ->
        IO.puts("#{algorithm}: #{x} #{y}")
        loop()

      :eof ->
        :ok
    end
  end
end
