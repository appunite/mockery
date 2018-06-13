defmodule Mockery.Utils do
  @moduledoc false

  import Mockery.Macro

  alias Mockery.Error

  # Helpers for manipulating process dict
  def get_mock(mod, fun) do
    mod
    |> dict_mock_key(fun)
    |> Process.get()
  end

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

  # Removes unnecessary `Elixir.` prefix from module names
  def print_mod(mod), do: mod |> to_string |> remove_elixir_prefix()

  # Helper for Mockery.History
  def history_enabled? do
    Process.get(
      Mockery.History,
      mockable(Application).get_env(:mockery, :history, false)
    )
  end

  # Helper for global mock
  # Global mock cannot export function that the original module
  # does not export
  def validate_global_mock!(original, mock) do
    original_exports = original.module_info[:exports]
    mock_exports = mock.module_info[:exports] -- [__info__: 1]

    case Enum.reject(mock_exports, &(&1 in original_exports)) do
      [] ->
        :ok

      unknown ->
        raise Error, """
        Global mock "#{print_mod(mock)}" exports functions unknown to \
        "#{print_mod(original)}" module:

            #{inspect(unknown)}

        Remove or fix them.
        """
    end
  end

  defp remove_elixir_prefix("Elixir." <> rest), do: rest
  defp remove_elixir_prefix(erlang_mod), do: ":#{erlang_mod}"

  # KEYS
  # note to myself: dont use three element tuples

  # key used to assign mocked value to given function
  defp dict_mock_key(mod, [{fun, arity}]), do: {Mockery, {mod, {fun, arity}}}
  defp dict_mock_key(mod, fun), do: {Mockery, {mod, fun}}

  # function calls are stored under this key
  defp dict_called_key(mod, fun), do: {Mockery.Assertions, {mod, fun}}
end
