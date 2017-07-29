defmodule Mockery.Utils do
  @moduledoc false #this module is private to Mockery

  def get_calls(mod, fun) do
    key = dict_called_key(mod, fun)

    Process.get(key, [])
  end

  def push_call(mod, fun, arity, args) do
    key = dict_called_key(mod, fun)

    Process.put(key, [{arity, args} | get_calls(mod, fun)])
  end

  # KEYS
  # note to myself: dont use three element tuples

  # key used to assign mocked value to given function
  def dict_mock_key(mod, [{fun, arity}]),
    do: {Mockery, {mod, {fun, arity}}}
  def dict_mock_key(mod, fun),
    do: {Mockery, {mod, fun}}

  # function calls are stored under this key
  defp dict_called_key(mod, fun),
    do: {Mockery.Assertions, {mod, fun}}
end
