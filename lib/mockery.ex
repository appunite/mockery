defmodule Mockery do
  @moduledoc """
  Core functionality
  """
  alias Mockery.Utils

  @doc """
  Function used to prepare module for mocking.

  For MIX_ENV other than :test it returns first argument unchanged.
  For test env it creates kind of proxy to oryginal module.

  Proxy can be implicit

      @module Mockery.of(MyApp.Module)

  or explicit

      @module Mockery.of(MyApp.Module, by: MyApp.FakeModule)

  Explicit version is used for global mocks. For more information see
  `Mockery.Heritage`
  """
  def of(mod, opts \\ []) do
    env = opts[:env] || Mix.env

    cond do
      env != :test ->
        mod
      by = Keyword.get(opts, :by) ->
        {by, :ok}
      :else ->
        {Mockery.Proxy, mod}
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
  """
  def mock(mod, fun, value) do
    Process.put(Utils.dict_mock_key(mod, fun), value)
  end
end
