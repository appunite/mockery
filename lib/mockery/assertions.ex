defmodule Mockery.Assertions do
  @moduledoc """
  This module contains a set of additional assertion functions.
  """

  alias Mockery.Utils

  @doc """
  Asserts that function from given module with given name or name and arity
  was called at least once.

  **NOTE**: Mockery doesn't keep track of function calls on modules that
  weren't prepared by `Mockery.of/2` and for MIX_ENV other than :test

  ## Examples

  Assert Mod.fun/2 was called

      assert_called Mod, fun: 2

  Assert any function named :fun from module Mod was called

      assert_called Mod, :fun

  """
  def assert_called(mod, [{fun, arity}]),
    do: ExUnit.Assertions.assert called?(mod, fun, arity), "#{mod}.#{fun}/#{arity} was not called"
  def assert_called(mod, fun),
    do: ExUnit.Assertions.assert called?(mod, fun), "#{mod}.#{fun} was not called"

  @doc """
  Asserts that function from given module with given name or name and arity
  was NOT called.

  **NOTE**: Mockery doesn't keep track of function calls on modules that
  weren't prepared by `Mockery.of/2` and for MIX_ENV other than :test

  ## Examples

  Assert Mod.fun/2 wasn't called

      refute_called Mod, fun: 2

  Assert any function named :fun from module Mod wasn't called

      refute_called Mod, :fun

  """
  def refute_called(mod, [{fun, arity}]),
    do: ExUnit.Assertions.refute called?(mod, fun, arity), "#{mod}.#{fun}/#{arity} was called at least once"
  def refute_called(mod, fun),
    do: ExUnit.Assertions.refute called?(mod, fun), "#{mod}.#{fun} was called at least once"

  @doc """
  Asserts that function from given module with given name was called
  at least once with arguments matching given pattern.

  **NOTE**: Mockery doesn't keep track of function calls on modules that
  weren't prepared by `Mockery.of/2` and for MIX_ENV other than :test

  ## Examples

  Assert Mod.fun/2 was called with given args list

      assert_called Mod, :fun, ["a", "b"]

  You can also use unbound variables inside args pattern

      assert_called Mod, :fun, ["a", _second]

  """
  defmacro assert_called(mod, fun, args) do
    quote do
      ExUnit.Assertions.assert unquote(called_with?(mod, fun, args)), unquote(message(mod, fun))
    end
  end

  @doc """
  Asserts that function from given module with given name was NOT called
  with arguments matching given pattern.

  **NOTE**: Mockery doesn't keep track of function calls on modules that
  weren't prepared by `Mockery.of/2` and for MIX_ENV other than :test

  ## Examples

  Assert Mod.fun/2 wasn't called with given args list

      refute_called Mod, :fun, ["a", "b"]

  You can also use unbound variables inside args pattern

      refute_called Mod, :fun, ["a", _second]

  """
  defmacro refute_called(mod, fun, args) do
    quote do
      ExUnit.Assertions.refute unquote(called_with?(mod, fun, args)), unquote(refute_message(mod, fun))
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

  defp refute_message(mod, fun) do
    quote do
      "#{unquote(mod)}.#{unquote(fun)} was called with given arguments at least once"
    end
  end
end
