defmodule Mockery.Heritage do
  alias Mockery.Utils
  alias Mockery.Error

  defmacro __using__(opts) do
    mod = opts |> Keyword.fetch!(:module)

    Agent.start_link(fn-> mod end, name: __CALLER__.module)

    quote do
      import Mockery.Heritage, only: :macros

      def unquote(:"$handle_undefined_function")(name, args) do
        arity = Enum.count(args)
        fun_tuple = {name, arity}
        key1 = Utils.dict_mock_key(unquote(mod), [{name, arity}])
        key2 = Utils.dict_mock_key(unquote(mod), name)

        if fun_tuple in unquote(mod).__info__(:functions) do
          case Process.get(key1) || Process.get(key2) do
            nil ->
              apply(unquote(mod), name, args)
            fun when is_function(fun, arity) ->
              apply(fun, args)
            fun when is_function(fun) ->
              raise Error, "function used for mock should have same arity as original"
            value ->
              value
          end
        else
          md = __MODULE__ |> Module.split() |> Enum.join(".")

          raise Error, "function #{md}.#{name}/#{arity} is undefined or private"
        end
      end
    end
  end

  defmacro mock([{name, arity}], do: new_default) do
    mod = __CALLER__.module |> Agent.get(&(&1)) |> Macro.expand(__ENV__)

    args = mkargs(mod, arity)
    key1 = Utils.dict_mock_key(mod, [{name, arity}])
    key2 = Utils.dict_mock_key(mod, name)

    quote do
      def unquote(name)(unquote_splicing(args)) do
        case Process.get(unquote(key1)) || Process.get(unquote(key2)) do
          nil ->
            unquote(new_default)
          fun when is_function(fun, unquote(arity)) ->
            fun.(unquote_splicing(args))
          fun when is_function(fun) ->
            raise Error, "function used for mock should have same arity as original"
          value ->
            value
        end
      end
    end
  end

  # shamelessly stolen from
  # https://gist.github.com/teamon/f759a4ced0e21b02a51dda759de5da03
  defp mkargs(_, 0), do: []
  defp mkargs(mod, n), do: Enum.map(1..n, &Macro.var(:"arg#{&1}", mod))
end
