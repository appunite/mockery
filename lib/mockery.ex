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

  @typep global_mock :: module | nil

  @typedoc """
  Mockery uses tuple calls to send additional data to internal proxy module
  """
  @opaque proxy_tuple :: {Mockery.Proxy, module, global_mock}

  @typedoc """
  Used to avoid unnecessary compile-time dependencies between modules

  ## Examples

      defmodule Foo do
        # this creates compile-time dependency between Foo and Bar
        @bar1 Mockery.of(Bar)

        # same result but without compile-time dependency
        @bar2 Mockery.of("Bar")
      end

  `mix xref graph` can be used to check difference between module and string versions
  """
  @type elixir_module_as_string :: String.t()

  @doc """
  Function used to prepare module for mocking.

  For Mix.env other than :test it returns module given in the first argument.
  If Mix.env equal :test it creates a proxy to the original module.
  When Mix is missing it assumes that env is :prod

      @elixir_module Mockery.of("MyApp.Module")
      @erlang_module Mockery.of(:crypto)

  It is also possible to pass the module in elixir format

      @module Mockery.of(MyApp.Module)

  but it is not recommended as it creates an unnecessary compile-time dependency
  (see `mix xref graph` output for both versions).
  """
  @spec of(
          mod :: module | elixir_module_as_string,
          opts :: [by: module | elixir_module_as_string]
        ) :: module | proxy_tuple
  def of(mod, opts \\ [])
      when is_atom(mod)
      when is_binary(mod) do
    env = opts[:env] || mix_env()

    if env != :test do
      to_mod(mod)
    else
      do_proxy_tuple(mod, opts)
    end
  end

  @doc """
  Creates proxy to original module.

  In contrast to `Mockery.of/2` it always returns proxy no matter what environemnt
  is returned by `Mix.env/0`. User have to explicitely prepare module for mocking through
  application configs.

      # module
      @foo Application.get_env(:my_app, :foo, MyApp.Foo)

      # MIX_ENV=test iex -S mix
      iex(1)> Mockery.new(MyApp.Foo)
      {Mockery.Proxy, MyApp.Foo, nil}

      # config/test.exs
      config :my_app, :bar, {Mockery.Proxy, MyApp.Foo, nil}

  """
  @spec new(
          mod :: module | elixir_module_as_string,
          opts :: [by: module | elixir_module_as_string]
        ) :: proxy_tuple
  def new(mod, opts \\ [])
      when is_atom(mod)
      when is_binary(mod) do
    do_proxy_tuple(mod, opts)
  end

  defp do_proxy_tuple(mod, opts) do
    {Mockery.Proxy, to_mod(mod), to_mod(opts[:by])}
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
    Dynamic mock requires [function: arity] syntax.

    Please use:
        mock(#{Utils.print_mod(mod)}, [#{fun}: #{arity}], fn(...) -> ... end)
    """
  end

  def mock(mod, fun, nil), do: do_mock(mod, fun, Mockery.Nil)
  def mock(mod, fun, false), do: do_mock(mod, fun, Mockery.False)
  def mock(mod, fun, value), do: do_mock(mod, fun, value)

  defp do_mock(mod, fun, value) do
    Utils.put_mock(mod, fun, value)

    mod
  end

  @compile {:inline, mix_env: 0}
  defp mix_env do
    if function_exported?(Mix, :env, 0), do: Mix.env(), else: :prod
  end
end
