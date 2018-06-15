defmodule Mockery.Proxy do
  @moduledoc false

  alias Mockery.Error
  alias Mockery.Utils

  def unquote(:"$handle_undefined_function")(name, args) do
    [{_proxy, mod, by} | rest] = Enum.reverse(args)
    args = Enum.reverse(rest)

    do_proxy(mod, name, args, by)
  end

  def do_proxy(mod, name, args, by) do
    arity = Enum.count(args)

    Utils.push_call(mod, name, arity, args)

    if {name, arity} in mod.module_info[:exports] do
      case Utils.get_mock(mod, [{name, arity}]) || Utils.get_mock(mod, name) do
        nil ->
          fallback_to_global_mock(mod, name, args, arity, by)

        Mockery.Nil ->
          nil

        Mockery.False ->
          false

        fun when is_function(fun, arity) ->
          apply(fun, args)

        fun when is_function(fun) ->
          raise Error, "function used for mock should have same arity as original"

        value ->
          value
      end
    else
      raise Error, """
      function #{Utils.print_mod(mod)}.#{name}/#{arity} \
      is undefined or private\
      """
    end
  end

  defp fallback_to_global_mock(mod, name, args, _arity, nil) do
    fallback_to_original(mod, name, args)
  end

  defp fallback_to_global_mock(mod, name, args, arity, global_mock) do
    Utils.validate_global_mock!(mod, global_mock)

    if {name, arity} in global_mock.module_info[:exports] do
      apply(global_mock, name, args)
    else
      fallback_to_original(mod, name, args)
    end
  end

  defp fallback_to_original(mod, name, args) do
    apply(mod, name, args)
  end
end
