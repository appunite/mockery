defmodule Mockery.Assertions do
  alias Mockery.Utils

  def assert_called(mod, [{fun, arity}]),
    do: ExUnit.Assertions.assert called?(mod, fun, arity), "#{mod}.#{fun}/#{arity} was not called"
  def assert_called(mod, fun),
    do: ExUnit.Assertions.assert called?(mod, fun), "#{mod}.#{fun} was not called"

  defmacro assert_called(mod, fun, args) do
    quote do
      ExUnit.Assertions.assert unquote(called_with?(mod, fun, args)), unquote(message(mod, fun))
    end
  end

  defp called?(mod, fun), do: Utils.get_calls(mod, fun) != []
  defp called?(mod, fun, arity) do
    mod
    |> Utils.get_calls(fun)
    |> Enum.any?(&match?({^arity, _}, &1))
  end

  defp called_with?(mod, fun, args) do
    quote do
      unquote(mod)
      |> Utils.get_calls(unquote(fun))
      |> Enum.any?(&match?({_, unquote(args)}, &1))
    end
  end

  defp message(mod, fun) do
    quote do
      "#{unquote(mod)}.#{unquote(fun)} was not called with given arguments"
    end
  end
end
