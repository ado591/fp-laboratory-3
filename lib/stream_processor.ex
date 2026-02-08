defmodule Interpolation.StreamProcessor do
  @moduledoc """
  streaming processor for pipeline
  """

  alias Interpolation.{Options, PointParser, State}

  @type output :: {atom(), float(), float()}

  @spec run(Options.t(), Enumerable.t(), (String.t() -> any())) :: :ok
  def run(%Options{} = opts, input_stream, output_fun) do
    state = %State{
      step: opts.step,
      algorithms: opts.algorithms,
      window: opts.window
    }

    final_state =
      Enum.reduce(input_stream, state, fn line, st ->
        {st2, outputs} = ingest_line(st, line)
        Enum.each(outputs, &output_fun.(format_output(&1)))
        st2
      end)

    emit_remaining(final_state, output_fun)
    :ok
  end

  @spec ingest_line(State.t(), String.t()) :: {State.t(), [output]}
  def ingest_line(state, line) do
    case PointParser.parse(line) do
      {:ok, point} -> ingest_point(state, point)
      :skip -> {state, []}
    end
  end

  @spec ingest_point(State.t(), {float(), float()}) :: {State.t(), [output]}
  def ingest_point(state, point) do
    state
    |> add_point(point)
    |> compute_outputs()
  end

  defp add_point(%State{points: pts} = state, {x, y}) do
    updated =
      [{x, y} | pts]
      |> Enum.uniq_by(fn {xi, _yi} -> xi end)
      |> Enum.sort_by(fn {xi, _yi} -> xi end)

    %State{state | points: updated}
  end

  defp compute_outputs(%State{points: []} = state), do: {state, []}

  defp compute_outputs(%State{next_x: nil} = state) do
    [{x0, _} | _] = state.points
    compute_outputs(%State{state | next_x: x0})
  end

  defp compute_outputs(%State{} = state) do
    {max_x, _} = List.last(state.points)
    do_compute(state, state.next_x, max_x, [])
  end

  defp do_compute(%State{} = state, nx, max_x, acc) when nx > max_x do
    {%State{state | next_x: nx}, Enum.reverse(acc)}
  end

  defp do_compute(%State{} = state, nx, max_x, acc) do
    outputs_for_x = run_algorithms(state, nx)

    if outputs_for_x == [] do
      {%State{state | next_x: nx}, Enum.reverse(acc)}
    else
      do_compute(state, nx + state.step, max_x, outputs_for_x ++ acc)
    end
  end

  defp run_algorithms(%State{algorithms: algs, points: pts, window: window}, x) do
    Enum.reduce(algs, [], fn
      :linear, acc ->
        case Interpolation.Algorithms.linear(pts, x) do
          nil -> acc
          y -> [{:linear, x, y} | acc]
        end

      :newton, acc ->
        case Interpolation.Algorithms.newton(pts, x, window) do
          nil -> acc
          y -> [{:newton, x, y} | acc]
        end
    end)
  end

  defp emit_remaining(%State{} = state, output_fun) do
    {_, outputs} = compute_outputs(state)
    Enum.each(outputs, &output_fun.(format_output(&1)))
  end

  defp format_output({alg, x, y}) do
    "#{alg}: #{x} #{y}"
  end
end