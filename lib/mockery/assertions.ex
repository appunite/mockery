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

  import ExUnit.Assertions

  @type function_name :: atom()

  @type arity_opt :: non_neg_integer()
  @type args_opt :: [term()]
  @type times_opt ::
          non_neg_integer()
          | {:in, [non_neg_integer()]}
          | {:in, Range.t()}
          | {:at_least, non_neg_integer()}
          | {:at_most, non_neg_integer()}

  @type opts :: [{:arity, arity_opt} | {:args, args_opt} | {:times, times_opt}]

  @doc since: "2.5.0"
  @spec assert_called!(module(), function_name(), opts) :: true | no_return()
  defmacro assert_called!(mod, fun, opts \\ []) do
    arity_opt = Keyword.get(opts, :arity, :no_arity)
    args_opt = Keyword.get(opts, :args, :no_args)
    times_opt = Keyword.get(opts, :times, :no_times)

    cond do
      arity_opt_invalid?(arity_opt, __CALLER__) ->
        quote do
          raise Mockery.Error,
                ":arity should be a non_neg_integer, provided: #{inspect(unquote(arity_opt))}"
        end

      args_opt_invalid?(args_opt) ->
        quote do
          raise Mockery.Error,
                ":args should be a list, provided: #{inspect(unquote(args_opt))}"
        end

      true ->
        warn_ast = Mockery.Assertions.warn_arity_and_args(arity_opt, args_opt)

        quote do
          unquote(warn_ast)

          assert unquote(mod)
                 |> Mockery.Utils.get_calls(unquote(fun))
                 |> unquote(Mockery.Assertions.handle_match(arity_opt, args_opt))
                 |> unquote(Mockery.Assertions.handle_times(times_opt, __CALLER__)),
                 unquote(Mockery.Assertions.error_msg(mod, fun, arity_opt, args_opt, times_opt))
        end
    end
  end

  defp arity_opt_invalid?(:no_arity, _caller), do: false

  defp arity_opt_invalid?(arity, caller) do
    arity = Macro.expand(arity, caller)

    not (is_integer(arity) && arity >= 0)
  end

  defp args_opt_invalid?(:no_args), do: false

  defp args_opt_invalid?(args) do
    not is_list(args)
  end

  @doc false
  def handle_match(arity_opt, args_opt)

  def handle_match(:no_arity, :no_args) do
    quote do: then(& &1)
  end

  def handle_match(arity, :no_args) do
    quote do: Enum.filter(&match?({unquote(arity), _}, &1))
  end

  def handle_match(_, args) do
    quote do: Enum.filter(&match?({_, unquote(args)}, &1))
  end

  @doc false
  # credo:disable-for-lines:1 Credo.Check.Refactor.CyclomaticComplexity
  def handle_times(times_opt, caller) do
    case Macro.expand(times_opt, caller) do
      :no_times ->
        quote do: then(&(not Enum.empty?(&1)))

      times when is_integer(times) and times >= 0 ->
        quote do: Enum.count() |> Kernel.==(unquote(times))

      {:in, enum} when is_list(enum) ->
        quote do: Enum.count() |> Kernel.in(unquote(enum))

      {:in, {:%{}, [], [{:__struct__, Range} | _]} = range_ast} ->
        quote do: Enum.count() |> Kernel.in(unquote(range_ast))

      {:at_least, times} when is_integer(times) and times >= 0 ->
        quote do: Enum.count() |> Kernel.>=(unquote(times))

      {:at_most, times} when is_integer(times) and times >= 0 ->
        quote do: Enum.count() |> Kernel.<=(unquote(times))

      _ ->
        quote do
          then(fn _ ->
            raise Mockery.Error,
                  ":times have invalid format, provided: #{inspect(unquote(times_opt))}"
          end)
        end
    end
  end

  @doc false
  def error_msg(mod, fun, arity, args, times)

  def error_msg(mod, fun, :no_arity, :no_args, :no_times) do
    quote do
      "#{inspect(unquote(mod))}.#{unquote(fun)}/x was not called"
    end
  end

  def error_msg(mod, fun, :no_arity, :no_args, _) do
    quote do
      "#{inspect(unquote(mod))}.#{unquote(fun)}/x was not called expected number of times"
    end
  end

  def error_msg(mod, fun, arity, :no_args, :no_times) do
    quote do
      "#{inspect(unquote(mod))}.#{unquote(fun)}/#{unquote(arity)} was not called"
    end
  end

  def error_msg(mod, fun, arity, :no_args, _times) do
    quote do
      "#{inspect(unquote(mod))}.#{unquote(fun)}/#{unquote(arity)} was not called expected number of times"
    end
  end

  def error_msg(mod, fun, _arity, args, :no_times) when is_list(args) do
    arity = Enum.count(args)

    quote do
      "#{inspect(unquote(mod))}.#{unquote(fun)}/#{unquote(arity)} was not called with given args"
    end
  end

  def error_msg(mod, fun, _arity, args, _times) when is_list(args) do
    arity = Enum.count(args)

    quote do
      "#{inspect(unquote(mod))}.#{unquote(fun)}/#{unquote(arity)} was not called with given args expected number of times"
    end
  end

  @doc false
  def warn_arity_and_args(:no_arity, :no_args), do: :ok
  def warn_arity_and_args(_arity_opt, :no_args), do: :ok
  def warn_arity_and_args(:no_arity, _args_opt), do: :ok

  def warn_arity_and_args(_arity_opt, _args_opt) do
    warn =
      ":arity and :args options are mutually exclusive in assert_called!/3, " <>
        ":arity will be ignored"

    quote do
      IO.warn(unquote(warn))
    end
  end
end
