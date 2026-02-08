defmodule Interpolation.Options do
  @moduledoc """
  handles command-line argument parsing for interpolation parameters
  """

  defstruct algorithms: [:linear], step: 0.1, window: 4

  @type t :: %__MODULE__{
          algorithms: [atom()],
          step: float(),
          window: pos_integer()
        }

  @spec parse([String.t()]) :: t
  def parse(argv) do
    {opts, _, _} =
      OptionParser.parse(argv,
        switches: [
          linear: :boolean,
          newton: :boolean,
          step: :float,
          n: :integer
        ]
      )

    algorithms = pick_algorithms(opts)
    step = Keyword.get(opts, :step, 0.1)
    window = Keyword.get(opts, :n, 4)

    validate!(step, window)

    %__MODULE__{algorithms: algorithms, step: step, window: window}
  end

  defp pick_algorithms(opts) do
    [:linear, :newton]
    |> Enum.filter(&Keyword.get(opts, &1, false))
    |> case do
      [] -> [:linear]
      list -> list
    end
  end

  defp validate!(step, window) do
    cond do
      step <= 0.0 ->
        raise ArgumentError,
              "step must be positive, actual: #{inspect(step)}"

      not is_integer(window) or window < 2 ->
        raise ArgumentError,
              "window size must be integer not less or equal 2, actual: #{inspect(window)}"

      true ->
        :ok
    end
  end
end
