defmodule Interpolation.Calculate do
  @moduledoc """
  Stateful process that receives data points,
  applies selected interpolation algorithms,
  and sends results to the printer process
  """
  def start(algorithms, step, window, printer_pid) do
    state = %{
      points: [],
      last_linear_x: nil,
      window_queue: [],
      algorithms: algorithms,
      step: step,
      window: window,
      printer: printer_pid,
      is_first_window: true,
      last_window_processed: []
    }

    loop(state)
  end

  defp loop(state) do
    receive do
      {:data_point, {x, y}} ->
        new_state = add_point_and_process(state, {x, y})
        loop(new_state)

      :eof ->
        do_final_calculations(state)
        send(state.printer, :eof)
    end
  end

  defp add_point_and_process(state, {x, y}) do
    new_points = [{x, y} | state.points] |> Enum.sort_by(&elem(&1, 0))

    new_window_queue = new_points |> Enum.take(-state.window) |> Enum.sort_by(&elem(&1, 0))

    updated_state = %{state | points: new_points, window_queue: new_window_queue}

    state_after_linear =
      if :linear in state.algorithms and length(new_points) >= 2 do
        process_linear(updated_state)
      else
        updated_state
      end

    window_algs = Enum.filter(state.algorithms, &(&1 != :linear))
    min_points_for_window = if not Enum.empty?(window_algs), do: state.window, else: 0

    if not Enum.empty?(window_algs) and length(new_window_queue) >= min_points_for_window do
      process_window(state_after_linear, window_algs)
    else
      state_after_linear
    end
  end

  defp process_linear(state) do
    sorted = Enum.sort_by(state.points, &elem(&1, 0))

    if length(sorted) >= 2 do
      [{x1, y1}, {x2, _y2}] = Enum.take(sorted, -2)

      if state.last_linear_x == nil do
        send(state.printer, {:result, :linear, x1, y1})
      end

      start_x = state.last_linear_x || x1
      last_x = calc_linear_range(state, start_x, x2, sorted)

      %{state | last_linear_x: last_x}
    else
      state
    end
  end

  defp calc_linear_range(state, start_x, end_x, all_points) do
    next_x = if state.last_linear_x == nil, do: start_x + state.step, else: start_x + state.step

    if next_x < end_x do
      window_pts =
        all_points
        |> Enum.sort_by(fn {px, _} -> abs(px - next_x) end)
        |> Enum.take(2)
        |> Enum.sort_by(&elem(&1, 0))

      if length(window_pts) >= 2 do
        y = Interpolation.Algorithms.linear(next_x, window_pts)
        send(state.printer, {:result, :linear, next_x, y})
      end

      calc_linear_range(%{state | last_linear_x: next_x}, next_x, end_x, all_points)
    else
      state.last_linear_x || start_x
    end
  end

  defp process_window(state, window_algs) do
    current_window = state.window_queue

    window_changed =
      state.last_window_processed == [] or current_window != state.last_window_processed

    if window_changed do
      sorted_window = Enum.sort_by(current_window, &elem(&1, 0))
      {first_x, _} = List.first(sorted_window)
      {last_x, _} = List.last(sorted_window)

      if state.is_first_window do
        Enum.each(sorted_window, fn {x, y} ->
          Enum.each(window_algs, fn alg ->
            send(state.printer, {:result, alg, x, y})
          end)
        end)

        calc_window_many_points(state, sorted_window, first_x, last_x, window_algs)
        %{state | is_first_window: false, last_window_processed: current_window}
      else
        center_x = (first_x + last_x) / 2
        calc_window_single_point(state, sorted_window, center_x, window_algs)
        %{state | last_window_processed: current_window}
      end
    else
      state
    end
  end

  defp calc_window_many_points(state, window_points, start_x, end_x, algorithms) do
    calc_window_many_points_rec(state, window_points, start_x, end_x, algorithms)
  end

  defp calc_window_many_points_rec(state, window_points, current_x, end_x, algorithms) do
    if current_x <= end_x do
      Enum.each(algorithms, fn alg ->
        y = calc_algorithm(alg, current_x, window_points, state.window)
        send(state.printer, {:result, alg, current_x, y})
      end)

      next_x = current_x + state.step

      if next_x <= end_x do
        calc_window_many_points_rec(state, window_points, next_x, end_x, algorithms)
      end
    end
  end

  defp calc_window_single_point(state, window_points, center_x, algorithms) do
    Enum.each(algorithms, fn alg ->
      y = calc_algorithm(alg, center_x, window_points, state.window)
      send(state.printer, {:result, alg, center_x, y})
    end)
  end

  defp do_final_calculations(state) do
    window_algs = Enum.filter(state.algorithms, &(&1 != :linear))
    has_linear = :linear in state.algorithms

    if not Enum.empty?(window_algs) and not Enum.empty?(state.points) do
      # Последнее окно: вычисляем точки после последней входной точки
      if length(state.window_queue) >= state.window do
        sorted_window = Enum.sort_by(state.window_queue, &elem(&1, 0))
        {last_x, _} = List.last(sorted_window)
        end_x = last_x + state.step * 3

        calc_final_window_points(state, sorted_window, last_x, end_x, window_algs)
      end
    end

    if has_linear and length(state.points) >= 2 do
      sorted_points = Enum.sort_by(state.points, &elem(&1, 0))
      {last_x, last_y} = List.last(sorted_points)

      send(state.printer, {:result, :linear, last_x, last_y})

      start_x = state.last_linear_x || last_x

      if start_x < last_x + state.step do
        calc_linear_range(state, start_x, last_x + state.step * 2, sorted_points)
      end
    end
  end

  defp calc_final_window_points(state, window_points, start_x, end_x, algorithms) do
    next_x = start_x + state.step

    if next_x <= end_x do
      Enum.each(algorithms, fn alg ->
        y = calc_algorithm(alg, next_x, window_points, state.window)
        send(state.printer, {:result, alg, next_x, y})
      end)

      calc_final_window_points(state, window_points, next_x, end_x, algorithms)
    end
  end

  defp calc_algorithm(algorithm, x, points, window) do
    window_size =
      case algorithm do
        :linear -> min(2, window)
        _ -> min(window, length(points))
      end

    window_points =
      points
      |> Enum.take(window_size)
      |> Enum.sort_by(&elem(&1, 0))

    case algorithm do
      :linear -> Interpolation.Algorithms.linear(x, window_points)
      :newton -> Interpolation.Algorithms.newton(x, window_points)
    end
  end
end
