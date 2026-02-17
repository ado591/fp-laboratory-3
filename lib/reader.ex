defmodule Interpolation.Reader do
  @moduledoc """
  Reads input points from standard input
  and sends them to the calculation process.
  """
  def start_reader(calculator_pid) do
    read_loop(calculator_pid, 1)
  end

  def read_loop(calculator_pid, line) do
    case IO.read(:line) do
      :eof ->
        send(calculator_pid, :eof)
        :ok

      input_line ->
        case Interpolation.PointParser.parse(input_line) do
          {:ok, {x, y}} ->
            send(calculator_pid, {:data_point, {x, y}})
            read_loop(calculator_pid, line + 1)

          :skip ->
            read_loop(calculator_pid, line + 1)
        end
    end
  end
end
