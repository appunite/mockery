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
  def of(mod, opts \\ [])
  def of(mod, opts) when is_atom(mod) do
    env = opts[:env] || Mix.env

    cond do
      env != :test ->
        mod
      :else ->
        {Mockery.Proxy, mod}
    end
  end
  def of(mod, opts) when is_binary(mod) do
    env = opts[:env] || Mix.env

    cond do
      env != :test ->
        Module.concat([mod])
      :else ->
        {Mockery.Proxy, Module.concat([mod])}
    end
  end

  @doc """
  Function used to create mock in context of single test.

  Mock created in one test won't leak to another.
  It can be used safely in asynchronous tests.

  Mocks can be created with value:

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

  But this:

      mock Mod, :fun, &string/1

  doesn't make any sense, because it will only work for Mod.fun/1.

  Also, multiple mocks for same module can be chainable

      Mod
      |> mock(:fun1, "value")
      |> mock([fun2: 1], &string/1)

  """
  def mock(mod, fun, value \\ :mocked)

  def mock(mod, fun, nil) do
    Process.put(Utils.dict_mock_key(mod, fun), Mockery.Nil)

    mod
  end
  def mock(mod, fun, false) do
    Process.put(Utils.dict_mock_key(mod, fun), Mockery.False)

    mod
  end
  def mock(mod, fun, value) do
    Process.put(Utils.dict_mock_key(mod, fun), value)

    mod
  end
end
