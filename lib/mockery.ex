defmodule Mockery do
  defmodule Error do
    defexception message: ""
  end

  def mock(mod, fun, value) do
    Process.put(dict_mock_key(mod, fun), value)
  end

  defmacro global_mock(mod, [{name, arity}], do: new_default) do
    mod = Macro.expand(mod, __ENV__)
    args = mkargs(mod, arity)

    key1 = dict_mock_key(mod, [{name, arity}])
    key2 = dict_mock_key(mod, name)

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

  defmacro __using__(opts) do
    mod = opts |> Keyword.fetch!(:module)

    quote do
      require unquote(mod)

      import Mockery, only: :macros

      unquote(generate_funs(mod))
      unquote(make_overridable(mod))
    end
  end

  defp generate_funs(mod) do
    mod = Macro.expand(mod, __ENV__)

    mod.__info__(:functions)
    |> Enum.map(fn {name, arity} ->
      args = mkargs(mod, arity)

      key1 = dict_mock_key(mod, [{name, arity}])
      key2 = dict_mock_key(mod, name)

      quote do
        def unquote(name)(unquote_splicing(args)) do
          case Process.get(unquote(key1)) || Process.get(unquote(key2)) do
            nil ->
              apply(unquote(mod), unquote(name), [unquote_splicing(args)])
            fun when is_function(fun, unquote(arity)) ->
              fun.(unquote_splicing(args))
            fun when is_function(fun) ->
              raise Error, "function used for mock should have same arity as original"
            value ->
              value
          end
        end
      end
    end)
  end

  defp make_overridable(mod) do
    mod = Macro.expand(mod, __ENV__)
    funs = mod.__info__(:functions)

    quote do
      defoverridable unquote(funs)
    end
  end

  # note to myself: dont use three element tuples
  defp dict_mock_key(mod, [{funn, arity}]), do: {:mockery, {mod, {funn, arity}}}
  defp dict_mock_key(mod, funn), do: {:mockery, {mod, funn}}

  # shamelessly stolen from
  # https://gist.github.com/teamon/f759a4ced0e21b02a51dda759de5da03
  defp mkargs(_, 0), do: []
  defp mkargs(mod, n), do: Enum.map(1..n, &Macro.var(:"arg#{&1}", mod))
end
