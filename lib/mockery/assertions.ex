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

  @doc deprecated: "Use assert_called!/3 instead"
  def assert_called(mod, [{fun, arity}]) do
    warn =
      "assert_called/2 is deprecated, use assert_called!/3 instead: " <>
        "`assert_called!(#{Macro.to_string(mod)}, #{Macro.to_string(fun)}, arity: #{Macro.to_string(arity)})`"

    IO.warn(warn)

    ExUnit.Assertions.assert(
      called?(mod, fun, arity),
      "#{Utils.print_mod(mod)}.#{fun}/#{arity} was not called"
    )
  end

  def assert_called(mod, fun) do
    warn =
      "assert_called/2 is deprecated, use assert_called!/3 instead: " <>
        "`assert_called!(#{Macro.to_string(mod)}, #{Macro.to_string(fun)})`"

    IO.warn(warn)

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

  @doc deprecated: "Use assert_called!/3 instead"
  defmacro assert_called(mod, fun, args) do
    mod = Macro.expand(mod, __CALLER__)
    args = Macro.expand(args, __CALLER__)

    warn =
      "assert_called/3 is deprecated, use assert_called!/3 instead: " <>
        "`assert_called!(#{Macro.to_string(mod)}, #{Macro.to_string(fun)}, args: #{Macro.to_string(args)})`"

    IO.warn(warn, __CALLER__)

    quote do
      ExUnit.Assertions.assert(unquote(called_with?(mod, fun, args)), """
      #{unquote(Utils.print_mod(mod))}.#{unquote(fun)} \
      was not called with given arguments
      #{unquote(History.print(mod, fun, args))} \
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
      was called with given arguments at least once
      #{unquote(History.print(mod, fun, args))} \
      """)
    end
  end

  defp times_to_warn(times, caller) do
    case times do
      {:.., _, _} = ast ->
        "{:in, #{Macro.to_string(ast)}}"

      ast ->
        case Macro.expand(ast, caller) do
          ast when is_integer(ast) ->
            "#{Macro.to_string(ast)}"

          ast ->
            "{:in, #{Macro.to_string(ast)}}"
        end
    end
  end

  # defp times_to_warn(times_ast) do
  #   "{:in, #{Macro.to_string(times_ast)}}"
  # end

  @doc deprecated: "Use assert_called!/3 instead"
  defmacro assert_called(mod, fun, args, times) do
    mod = Macro.expand(mod, __CALLER__)
    args = Macro.expand(args, __CALLER__)

    warn =
      "assert_called/4 is deprecated, use assert_called!/3 instead: " <>
        "`assert_called!(#{Macro.to_string(mod)}, #{Macro.to_string(fun)}," <>
        " args: #{Macro.to_string(args)}, times: #{times_to_warn(times, __CALLER__)})`"

    IO.warn(warn, __CALLER__)

    quote do
      ExUnit.Assertions.assert(unquote(ncalled_with?(mod, fun, args, times)), """
      #{unquote(Utils.print_mod(mod))}.#{unquote(fun)} \
      was not called with given arguments expected number of times
      #{unquote(History.print(mod, fun, args))} \
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
      was called with given arguments unexpected number of times
      #{unquote(History.print(mod, fun, args))} \
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

  @typedoc "Function name (an atom identifying the function)."
  @type function_name :: atom()

  @typedoc """
  Option value for the `:arity` key in `opts`.

  A non-negative integer narrowing the match to a specific function arity.
  """
  @type arity_opt :: non_neg_integer()

  @typedoc """
  Option value for the `:args` key in `opts`.

  A list of terms representing the argument pattern to match recorded calls.
  """
  @type args_opt :: [term()]

  @typedoc """
  Option value for the `:times` key in `opts`.

  How many times the function is expected to be called.

  Accepts:
    - a non-negative integer for exact count
    - `{:in, [integers]}` for specific allowed counts
    - `{:in, Range.t()}` for a range of allowed counts
    - `{:at_least, non_neg_integer()}` for a lower bound
    - `{:at_most, non_neg_integer()}` for an upper bound
  """
  @type times_opt ::
          non_neg_integer()
          | {:in, [non_neg_integer()]}
          | {:in, Range.t()}
          | {:at_least, non_neg_integer()}
          | {:at_most, non_neg_integer()}

  @typedoc """
  Keyword options accepted by `assert_called!/3`.

  Supported keys: `:arity`, `:args`, and `:times`.
  """
  @type opts :: [{:arity, arity_opt} | {:args, args_opt} | {:times, times_opt}]

  @doc """
  Asserts that a function on the given `mod` with the given `fun` name was called.

  This macro is a convenience wrapper that allows you to assert calls with
  additional filtering via options.

  Accepted options:
    * `:arity` - a non-negative integer narrowing the check to calls with the given arity.
    * `:args` - a list representing the argument pattern to match recorded calls.
      Use unbound variables (e.g. `_`, `var`) to create flexible patterns.
    * `:times` - how many times the function is expected to be called.
      Supports an integer, `{:in, [integers]}`, `{:in, Range.t()}`, `{:at_least, n}` and
      `{:at_most, n}`.

  Notes:
    * `:arity` and `:args` are mutually exclusive. If both are provided, `:arity`
      will be ignored and a warning will be emitted.
    * If provided, `:args` must be a list — otherwise a `Mockery.Error` will be raised.
    * If provided, `:arity` must be a non-negative integer — otherwise a `Mockery.Error` will be raised.
    * If `:times` has an invalid format a `Mockery.Error` will be raised.

  Returns `true` when the assertion passes. On failure it raises an error
  with a descriptive message and (when history is enabled) a snippet of the recorded calls.

  ## Examples

      # Assert any function named :fun on Mod was called at least once
      assert_called! Mod, :fun

      # Assert Mod.fun/2 was called
      assert_called! Mod, :fun, arity: 2

      # Assert Mod.fun/2 was called with specific args (supports patterns)
      assert_called! Mod, :fun, args: ["a", _]

      # Assert Mod.fun/2 was called exactly 3 times
      assert_called! Mod, :fun, times: 3

      # Assert Mod.fun/1 was called at least twice
      assert_called! Mod, :fun, arity: 1, times: {:at_least, 2}

  """
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
        warn_ast = warn_arity_and_args(arity_opt, args_opt)

        match_handler = handle_match(arity_opt, args_opt)
        times_handler = handle_times(times_opt, __CALLER__)

        mod = Macro.expand(mod, __CALLER__)
        fun = Macro.expand(fun, __CALLER__)

        error_msg = error_msg(mod, fun, arity_opt, args_opt, times_opt)

        args_for_history =
          opts |> Keyword.get(:args) |> Macro.expand(__CALLER__)

        quote do
          unquote(warn_ast)

          assert unquote(mod)
                 |> Mockery.Utils.get_calls(unquote(fun))
                 |> unquote(match_handler)
                 |> unquote(times_handler),
                 "#{unquote(error_msg)}\n#{unquote(History.print(mod, fun, args_for_history))}"
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

  defp handle_match(arity_opt, args_opt)

  defp handle_match(:no_arity, :no_args) do
    quote do: then(& &1)
  end

  defp handle_match(arity, :no_args) do
    quote do: Enum.filter(&match?({unquote(arity), _}, &1))
  end

  defp handle_match(_, args) do
    quote do: Enum.filter(&match?({_, unquote(args)}, &1))
  end

  # credo:disable-for-lines:1 Credo.Check.Refactor.CyclomaticComplexity
  defp handle_times(times_opt, caller) do
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

  defp error_msg(mod, fun, arity, args, times)

  defp error_msg(mod, fun, :no_arity, :no_args, :no_times) do
    "#{inspect(mod)}.#{fun}/x was not called"
  end

  defp error_msg(mod, fun, :no_arity, :no_args, _) do
    "#{inspect(mod)}.#{fun}/x was not called expected number of times"
  end

  defp error_msg(mod, fun, arity, :no_args, :no_times) do
    "#{inspect(mod)}.#{fun}/#{arity} was not called"
  end

  defp error_msg(mod, fun, arity, :no_args, _times) do
    "#{inspect(mod)}.#{fun}/#{arity} was not called expected number of times"
  end

  defp error_msg(mod, fun, _arity, args, :no_times) when is_list(args) do
    arity = Enum.count(args)

    "#{inspect(mod)}.#{fun}/#{arity} was not called with given args"
  end

  defp error_msg(mod, fun, _arity, args, _times) when is_list(args) do
    arity = Enum.count(args)

    "#{inspect(mod)}.#{fun}/#{arity} was not called with given args expected number of times"
  end

  defp warn_arity_and_args(:no_arity, :no_args), do: :ok
  defp warn_arity_and_args(_arity_opt, :no_args), do: :ok
  defp warn_arity_and_args(:no_arity, _args_opt), do: :ok

  defp warn_arity_and_args(_arity_opt, _args_opt) do
    warn =
      ":arity and :args options are mutually exclusive in assert_called!/3, " <>
        ":arity will be ignored"

    quote do
      IO.warn(unquote(warn))
    end
  end
end
