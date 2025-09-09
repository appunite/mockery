defmodule Mockery.Assertions do
  @moduledoc """
  Additional assertion helpers for verifying calls made to mocked modules and functions in tests.

  This module provides macros and functions to assert whether certain functions have been called,
  how many times they have been called, and with what arguments.

  > #### Important Notes {: .warning}
  >
  > * Mockery only tracks calls to modules prepared by `Mockery.Macro.mockable/2`.
  >
  > * Tracking only works when the configuration `config :mockery, enable: true` is set.
  >
  > * Calls made outside the test process (such as those in spawned Tasks, GenServers, etc.) are not tracked.

  """

  alias Mockery.Error
  alias Mockery.History
  alias Mockery.Utils

  @doc """
  Asserts that function from given module with given name or name and arity
  was called at least once.

  ## Examples

  Assert Mod.fun/2 was called

      assert_called Mod, fun: 2

  Assert any function named :fun from module Mod was called

      assert_called Mod, :fun

  """
  def assert_called(mod, [{fun, arity}]) do
    ExUnit.Assertions.assert(
      called?(mod, fun, arity),
      "#{Utils.print_mod(mod)}.#{fun}/#{arity} was not called"
    )
  end

  def assert_called(mod, fun) do
    ExUnit.Assertions.assert(called?(mod, fun), "#{Utils.print_mod(mod)}.#{fun} was not called")
  end

  @doc """
  Asserts that function from given module with given name or name and arity
  was NOT called.

  ## Examples

  Assert Mod.fun/2 wasn't called

      refute_called Mod, fun: 2

  Assert any function named :fun from module Mod wasn't called

      refute_called Mod, :fun

  """
  def refute_called(mod, [{fun, arity}]) do
    ExUnit.Assertions.refute(
      called?(mod, fun, arity),
      "#{Utils.print_mod(mod)}.#{fun}/#{arity} was called at least once"
    )
  end

  def refute_called(mod, fun) do
    ExUnit.Assertions.refute(
      called?(mod, fun),
      "#{Utils.print_mod(mod)}.#{fun} was called at least once"
    )
  end

  @doc """
  Asserts that function from given module with given name was called
  at least once with arguments matching given pattern.

  ## Examples

  Assert Mod.fun/2 was called with given args list

      assert_called Mod, :fun, ["a", "b"]

  You can also use unbound variables inside args pattern

      assert_called Mod, :fun, ["a", _second]

  """
  defmacro assert_called(mod, fun, args) do
    mod = Macro.expand(mod, __CALLER__)
    args = Macro.expand(args, __CALLER__)

    quote do
      ExUnit.Assertions.assert(unquote(called_with?(mod, fun, args)), """
      #{unquote(Utils.print_mod(mod))}.#{unquote(fun)} \
      was not called with given arguments\
      #{unquote(History.print(mod, fun, args))}
      """)
    end
  end

  @doc """
  Asserts that function from given module with given name was NOT called
  with arguments matching given pattern.

  ## Examples

  Assert Mod.fun/2 wasn't called with given args list

      refute_called Mod, :fun, ["a", "b"]

  You can also use unbound variables inside args pattern

      refute_called Mod, :fun, ["a", _second]

  """
  defmacro refute_called(mod, fun, args) do
    mod = Macro.expand(mod, __CALLER__)
    args = Macro.expand(args, __CALLER__)

    quote do
      ExUnit.Assertions.refute(unquote(called_with?(mod, fun, args)), """
      #{unquote(Utils.print_mod(mod))}.#{unquote(fun)} \
      was called with given arguments at least once\
      #{unquote(History.print(mod, fun, args))}
      """)
    end
  end

  @doc """
  Asserts that function from given module with given name was called
  given number of times with arguments matching given pattern.

  Similar to `assert_called/3` but instead of checking if function was called
  at least once, it checks if function was called specific number of times.

  ## Examples

  Assert Mod.fun/2 was called with given args 5 times

      assert_called Mod, :fun, ["a", "b"], 5

  Assert Mod.fun/2 was called with given args from 3 to 5 times

      assert_called Mod, :fun, ["a", "b"], 3..5

  Assert Mod.fun/2 was called with given args 3 or 5 times

      assert_called Mod, :fun, ["a", "b"], [3, 5]

  """
  defmacro assert_called(mod, fun, args, times) do
    mod = Macro.expand(mod, __CALLER__)
    args = Macro.expand(args, __CALLER__)

    quote do
      ExUnit.Assertions.assert(unquote(ncalled_with?(mod, fun, args, times)), """
      #{unquote(Utils.print_mod(mod))}.#{unquote(fun)} \
      was not called with given arguments expected number of times\
      #{unquote(History.print(mod, fun, args))}
      """)
    end
  end

  @doc """
  Asserts that function from given module with given name was NOT called
  given number of times with arguments matching given pattern.

  Similar to `refute_called/3` but instead of checking if function was called
  at least once, it checks if function was called specific number of times.

  ## Examples

  Assert Mod.fun/2 was not called with given args 5 times

      refute_called Mod, :fun, ["a", "b"], 5

  Assert Mod.fun/2 was not called with given args from 3 to 5 times

      refute_called Mod, :fun, ["a", "b"], 3..5

  Assert Mod.fun/2 was not called with given args 3 or 5 times

      refute_called Mod, :fun, ["a", "b"], [3, 5]

  """
  defmacro refute_called(mod, fun, args, times) do
    mod = Macro.expand(mod, __CALLER__)
    args = Macro.expand(args, __CALLER__)

    quote do
      ExUnit.Assertions.refute(unquote(ncalled_with?(mod, fun, args, times)), """
      #{unquote(Utils.print_mod(mod))}.#{unquote(fun)} \
      was called with given arguments unexpected number of times\
      #{unquote(History.print(mod, fun, args))}
      """)
    end
  end

  defp called?(mod, fun), do: Utils.get_calls(mod, fun) != []

  defp called?(mod, fun, arity) do
    mod
    |> Utils.get_calls(fun)
    |> Enum.any?(&match?({^arity, _}, &1))
  end

  defp called_with?(mod, fun, args) when not is_list(args), do: args_should_be_list(mod, fun)

  defp called_with?(mod, fun, args) do
    quote do
      unquote(mod)
      |> Utils.get_calls(unquote(fun))
      |> Enum.any?(&match?({_, unquote(args)}, &1))
    end
  end

  defp ncalled_with?(mod, fun, args, _times) when not is_list(args),
    do: args_should_be_list(mod, fun)

  defp ncalled_with?(mod, fun, args, times) when is_integer(times) do
    quote do
      unquote(mod)
      |> Utils.get_calls(unquote(fun))
      |> Enum.count(&match?({_, unquote(args)}, &1))
      |> (&(&1 == unquote(times))).()
    end
  end

  defp ncalled_with?(mod, fun, args, times) do
    quote do
      unquote(mod)
      |> Utils.get_calls(unquote(fun))
      |> Enum.count(&match?({_, unquote(args)}, &1))
      |> (&(&1 in unquote(times))).()
    end
  end

  defp args_should_be_list(mod, fun) do
    quote do
      raise Error, "args for #{unquote(Utils.print_mod(mod))}.#{unquote(fun)} should be a list"
    end
  end
end
