defmodule Mockery.Assertions do
  alias Mockery.Utils

  def assert_called(mod, [{fun, arity}]),
    do: ExUnit.Assertions.assert called?(mod, fun, arity), "#{mod}.#{fun}/#{arity} was not called"
  def assert_called(mod, fun),
    do: ExUnit.Assertions.assert called?(mod, fun), "#{mod}.#{fun} was not called"

  defp called?(mod, fun), do: Utils.get_calls(mod, fun) != []
  defp called?(mod, fun, arity) do
    mod
    |> Utils.get_calls(fun)
    |> Enum.any?(&match?({^arity, _}, &1))
  end
end
