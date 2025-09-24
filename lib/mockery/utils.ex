defmodule Mockery.Utils do
  @moduledoc false

  alias Mockery.Error

  # Helpers for manipulating process dict
  def get_mock(mod, fun) do
    mod
    |> dict_mock_key(fun)
    |> Process.get()
  end

  # see Mockery.Proxy for explaination about Mockery.Nil and Mockery.False
  def put_mock(mod, fun, nil), do: put_mock(mod, fun, Mockery.Nil)
  def put_mock(mod, fun, false), do: put_mock(mod, fun, Mockery.False)

  def put_mock(mod, fun, value) do
    mod
    |> dict_mock_key(fun)
    |> Process.put(value)
  end

  def get_calls(mod, fun) do
    mod
    |> dict_called_key(fun)
    |> Process.get([])
  end

  def push_call(mod, fun, arity, args) do
    mod
    |> dict_called_key(fun)
    |> Process.put([{arity, args} | get_calls(mod, fun)])
  end

  # Helper for Mockery.History
  def history_enabled? do
    Process.get(Mockery.History, Application.get_env(:mockery, :history, false))
  end

  def raise_undefined(mod, fun, arity) do
    raise Error, "function #{inspect(mod)}.#{fun}/#{arity} is undefined or private"
  end

  # Helper for global mock
  # Global mock cannot export function that the original module
  # does not export
  def validate_global_mock!(original, mock) do
    original_exports = original.module_info()[:exports]
    mock_exports = mock.module_info()[:exports] -- [__info__: 1]

    case Enum.reject(mock_exports, &(&1 in original_exports)) do
      [] ->
        :ok

      unknown ->
        raise Error, """
        Global mock "#{inspect(mock)}" exports functions unknown to \
        "#{inspect(original)}" module:

            #{inspect(unknown)}

        Remove or fix them.
        """
    end
  end

  # KEYS
  # note to myself: dont use three element tuples

  # key used to assign mocked value to given function
  defp dict_mock_key(mod, [{fun, arity}]), do: {Mockery, {mod, {fun, arity}}}
  defp dict_mock_key(mod, fun), do: {Mockery, {mod, fun}}

  # function calls are stored under this key
  defp dict_called_key(mod, fun), do: {Mockery.Assertions, {mod, fun}}
end
