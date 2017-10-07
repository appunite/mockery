defmodule Mockery do
  @moduledoc """
  Core functionality
  """
  alias Mockery.Utils

  defmacro __using__(_opts) do
    quote do
      import Mockery
      import Mockery.Assertions
      import Mockery.History, only: [enable_history: 0, enable_history: 1]
    end
  end

  @opaque proxy      :: {module, module} | {module, :ok}
  @type keyword_opts :: [{atom(), any()}]

  @doc """
  Function used to prepare module for mocking.

  For MIX_ENV other than :test it returns first argument unchanged.
  For test env it creates kind of proxy to oryginal module.

      @elixir_module Mockery.of("MyApp.Module")
      @erlang_module Mockery.of(:crypto)

  It is also possible to pass module in elixir format

      @module Mockery.of(MyApp.Module)

  but is not recommended as it creates unnecessary compile-time dependency
  (see `mix xref graph` output for both versions).
  """
  @spec of(mod :: atom | String.t, opts :: keyword_opts) ::
    module | proxy
  def of(mod, opts \\ []) when is_atom(mod)
                          when is_binary(mod) do
    env = opts[:env] || Mix.env

    if env != :test do
      to_mod(mod)
    else
      {Mockery.Proxy, to_mod(mod), to_mod(opts[:by])}
    end
  end

  defp to_mod(nil), do: nil
  defp to_mod(mod) when is_atom(mod), do: mod
  defp to_mod(mod) when is_binary(mod), do: Module.concat([mod])

  @doc """
  Function used to create mock in context of single test.

  Mock created in one test won't leak to another.
  It can be used safely in asynchronous tests.

  Mocks can be created with static value:

      mock Mod, [fun: 2], "mocked value"

  or function:

      mock Mod, [fun: 2], fn(_, arg2) -> arg2 end

  Keep in mind that function inside mock must have same arity as
  original one.

  This:

      mock Mod, [fun: 2], &to_string/1

  will raise an error.

  It is also possible to mock function with given name and any arity

      mock Mod, :fun, "mocked value"

  but this version doesn't support function as value.

  Also, multiple mocks for same module are chainable

      Mod
      |> mock(:fun1, "value")
      |> mock([fun2: 1], &string/1)

  """
  def mock(mod, fun, value \\ :mocked)
  def mock(mod, fun, value) when is_atom(fun) and is_function(value) do
    {:arity, arity} = :erlang.fun_info(value, :arity)

    raise Mockery.Error, """
    Dynamic mock requires [funtion: arity] syntax.

    Please use:
        mock(#{Utils.print_mod mod}, [#{fun}: #{arity}], fn(...) -> ... end)
    """
  end
  def mock(mod, fun, nil),
    do: do_mock(mod, fun, Mockery.Nil)
  def mock(mod, fun, false),
    do: do_mock(mod, fun, Mockery.False)
  def mock(mod, fun, value),
    do: do_mock(mod, fun, value)

  defp do_mock(mod, fun, value) do
    Utils.put_mock(mod, fun, value)

    mod
  end
end
