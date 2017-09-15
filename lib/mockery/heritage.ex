defmodule Mockery.Heritage do
  @moduledoc """
  This module contains macros useful for mocking given function with same value
  in multiple tests.

  ## Usage

  Create helper module.

      defmodule FakeService do
        use Mockery.Heritage,
          module: MyApp.Service
      end

  This module can be passed to `Mockery.of/2` :by option.
  By default it creates proxy to original module.

  Let's add global mock.

      defmodule FakeService do
        use Mockery.Heritage,
          module MyApp.Service

        mock [fun: 2], do: "mocked value"
      end

  Now you don't have to call `Mockery.mock/3` in multiple tests.

  For more information about global mock macro see `mock/2`
  """

  alias Mockery.Utils
  alias Mockery.Error

  defmacro __using__(opts) do
    mod = opts |> Keyword.fetch!(:module)

    Agent.start_link(fn-> mod end, name: __CALLER__.module)

    quote do
      import Mockery.Heritage, only: :macros

      def unquote(:"$handle_undefined_function")(name, args) do
        [{_m, :ok} | rest] = Enum.reverse(args)
        args = Enum.reverse(rest)

        arity = Enum.count(args)
        fun_tuple = {name, arity}
        key1 = Utils.dict_mock_key(unquote(mod), [{name, arity}])
        key2 = Utils.dict_mock_key(unquote(mod), name)

        Utils.push_call(unquote(mod), name, arity, args)

        if fun_tuple in unquote(mod).module_info[:exports] do
          case Process.get(key1) || Process.get(key2) do
            nil ->
              apply(unquote(mod), name, args)
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
          md = __MODULE__ |> Utils.print_mod()

          raise Error, "function #{md}.#{name}/#{arity} is undefined or private"
        end
      end
    end
  end

  @doc """
  Macro used to create global mocks inside Heritage helper.

  Mocks can be created with value:

      mock [fun: 2], do: "mocked_value"

  or function:

      mock [fun: 2] do
        fn(_, arg2) -> arg2 end
      end

  Keep in mind that function inside mock must have same arity as
  original one.

  This:

      mock [fun: 2] do
        &to_string/1
      end

  will raise an error.
  """
  defmacro mock([{name, arity}], do: new_default) do
    mod = __CALLER__.module |> Agent.get(&(&1)) |> Macro.expand(__ENV__)
    new_default = new_default

    args = mkargs(mod, arity + 1)
    key1 = Utils.dict_mock_key(mod, [{name, arity}])
    key2 = Utils.dict_mock_key(mod, name)

    quote do
      def unquote(name)(unquote_splicing(args)) do
        case Process.get(unquote(key1)) || Process.get(unquote(key2)) do
          nil ->
            Mockery.Heritage.handle_nd(unquote_splicing([new_default, args, arity]))
          fun when is_function(fun, unquote(arity)) ->
            fun.(unquote_splicing(Enum.take(args, arity)))
          fun when is_function(fun) ->
            raise Error, "function used for mock should have same arity as original"
          value ->
            value
        end
      end
    end
  end

  @doc false #this function is private to Mockery
  def handle_nd(nd, args, arity) when is_function(nd, arity),
    do: apply(nd, Enum.take(args, arity))
  def handle_nd(nd, _args, _arity) when is_function(nd),
    do: raise Error, "function used for mock should have same arity as original"
  def handle_nd(nd, _args, _arity),
    do: nd

  # shamelessly stolen from
  # https://gist.github.com/teamon/f759a4ced0e21b02a51dda759de5da03
  defp mkargs(_, 0), do: []
  defp mkargs(mod, n), do: Enum.map(1..n, &Macro.var(:"arg#{&1}", mod))
end
