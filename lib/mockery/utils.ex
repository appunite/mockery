defmodule Mockery.Utils do
  @moduledoc false #this module is private to Mockery

  # note to myself: dont use three element tuples
  def dict_mock_key(mod, [{fun, arity}]), do: {:mockery, {mod, {fun, arity}}}
  def dict_mock_key(mod, fun), do: {:mockery, {mod, fun}}
end
