defmodule Mockery.Proxy do
  @moduledoc false #this module is private to Mockery

  alias Mockery.Utils
  alias Mockery.Error

  def unquote(:"$handle_undefined_function")(name, args) do
    [{_proxy, mod, by} | rest] = Enum.reverse(args)
    args = Enum.reverse(rest)

    arity = Enum.count(args)
    fun_tuple = {name, arity}
    key1 = Utils.dict_mock_key(mod, [{name, arity}])
    key2 = Utils.dict_mock_key(mod, name)

    Utils.push_call(mod, name, arity, args)

    if fun_tuple in mod.module_info[:exports] do
      case Process.get(key1) || Process.get(key2) do
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
      raise Error, "function #{Utils.print_mod mod}.#{name}/#{arity} is undefined or private"
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
