defmodule Mockery.History do
  @moduledoc """
  Provides calls history for Mockery.Assertions macros.

  It's disabled by default.
  It can be enabled/disabled globally by following config

      config :mockery, history: true

  Or for single test process

      Mockery.History.enable_history()
      Mockery.History.disable_history()

  Process config has higher priority than global config
  """
  import IO.ANSI
  alias Mockery.Utils

  @doc """
  Enables history in scope of single test process

      use Mockery

      test "example" do
        #...

        enable_history()
        assert_called! Foo, :bar, args: [_, :a]
      end

  """
  @doc since: "2.3.0"
  @spec enable_history :: :ok
  def enable_history do
    Process.put(__MODULE__, true)

    :ok
  end

  @doc """
  Disables history in scope of single test process

      use Mockery

      test "example" do
        #...

        disable_history()
        assert_called! Foo, :bar, args: [_, :a]
      end

  """
  @doc since: "2.3.0"
  @spec disable_history :: :ok
  def disable_history do
    Process.put(__MODULE__, false)

    :ok
  end

  @doc false
  def enabled? do
    Process.get(Mockery.History, Application.get_env(:mockery, :history, true))
  end

  # assert_called!/3 refute_called!/3
  @doc false
  def print(%{args: args, history_enabled: true} = params) when is_list(args) do
    %{mod: mod, fun: fun, binding: binding, expanded_args: expanded_args} = params

    formatted_module_attrs = format_module_attrs(params.module_attr_map)

    pins = collect_pins(args)
    formatted_pins = format_pins(pins, binding)

    formatted_different_arity_calls = format_different_arity_calls(mod, fun, Enum.count(args))

    """


    #{yellow()}Given:#{reset()}
    #{Macro.to_string(args)}#{if formatted_module_attrs || formatted_pins, do: "\n"}#{formatted_module_attrs}#{formatted_pins}

    #{yellow()}History:#{reset()}
    #{print_call_diffs(mod, fun, expanded_args, pins, binding)}#{formatted_different_arity_calls}
    """
  end

  def print(%{history_enabled: true} = params) do
    %{mod: mod, fun: fun, arity: arity} = params

    formatted_different_arity_calls = format_different_arity_calls(mod, fun, arity)

    """


    #{yellow()}History:#{reset()}
    #{print_calls(mod, fun, arity)}#{formatted_different_arity_calls}
    """
  end

  def print(_params), do: ""

  defp print_call_diffs(mod, fun, args, pins, binding) do
    arity = Enum.count(args)

    Utils.get_calls(mod, fun)
    |> Enum.reverse()
    |> Enum.reject(fn {call_arity, _call_args} -> call_arity != arity end)
    |> Enum.map_join("\n", fn {_call_arity, call_args} ->
      Mockery.History.Formatter.format(args, call_args, pins, binding)
    end)
    |> case do
      "" ->
        no_calls_msg()

      other ->
        String.trim_trailing(other)
    end
  end

  defp print_calls(mod, fun, arity) do
    Utils.get_calls(mod, fun)
    |> filter_calls_by_arity(arity)
    |> Enum.reverse()
    |> Enum.map_join("\n", fn {_call_arity, call_args} ->
      inspect(call_args)
    end)
    |> case do
      "" ->
        no_calls_msg()

      other ->
        other
    end
  end

  defp filter_calls_by_arity(calls, :no_arity), do: calls

  defp filter_calls_by_arity(calls, arity) do
    Enum.reject(calls, fn {call_arity, _call_args} -> call_arity != arity end)
  end

  defp format_different_arity_calls(_mod, _fun, :no_arity), do: nil

  defp format_different_arity_calls(mod, fun, arity) do
    Utils.get_calls(mod, fun)
    |> Enum.reverse()
    |> Enum.reject(fn {call_arity, _call_args} -> call_arity == arity end)
    |> Enum.reduce("", fn {_call_arity, call_args}, acc ->
      acc <> "#{inspect(call_args)}\n"
    end)
    |> case do
      "" ->
        nil

      calls ->
        header = "\n\n#{yellow()}History (same function name, different arity):#{reset()}\n"
        String.trim_trailing(header <> calls)
    end
  end

  defp collect_pins(args) do
    args
    |> Macro.prewalk([], fn
      {:^, _, [{var_name, _, _} = _var_ast]} = ast, acc ->
        {ast, [var_name | acc]}

      ast, acc ->
        {ast, acc}
    end)
    |> then(fn {_ast, acc} -> acc end)
    |> Enum.reverse()
    |> Enum.uniq()
  end

  defp format_pins([], _binding), do: nil

  defp format_pins(pins, binding) do
    pins
    |> Enum.sort()
    |> Enum.reduce("\n", fn pin, acc ->
      acc <> "#{pin} = #{inspect(binding[pin])}\n"
    end)
    |> String.trim_trailing()
  end

  defp format_module_attrs(attrs_map) when map_size(attrs_map) == 0, do: nil

  defp format_module_attrs(attrs_map) do
    attrs_map
    |> Enum.reduce("\n", fn {key, value}, acc ->
      acc <> "@#{key} #{value}\n"
    end)
    |> String.trim_trailing()
  end

  defp no_calls_msg do
    "(#{light_yellow()}#{underline()}empty - no function calls were registered#{reset()})"
  end
end
