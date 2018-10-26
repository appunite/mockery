defmodule Mockery do
  @moduledoc """
  Core functionality
  """
  alias Mockery.Utils

  defmacro __using__(_opts) do
    quote do
      import Mockery
      import Mockery.Assertions
      import Mockery.History, only: [enable_history: 0, enable_history: 1, disable_history: 0]
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

  ## Examples
  #### Prepare for mocking (elixir module)

      defmodule Foo do
        @bar Mockery.of("Bar")

        def foo do
          @bar.bar()
        end
      end

  It is also possible to pass the module in elixir format

      @bar Mockery.of(Bar)

  but it is not recommended as it creates an unnecessary compile-time dependency
  (see `mix xref graph` output for both versions).

  #### Prepare for mocking (erlang module)

      defmodule Foo do
        @crypto Mockery.of(:crypto)

        def foo do
          @crypto.rand_seed()
        end
      end

  #### Prepare for mocking with global mock

      # test/support/global_mocks/bar.ex
      defmodule BarGlobalMock do
        def bar, do: :mocked
      end

      # lib/foo.ex
      defmodule Foo do
        @bar Mockery.of(Bar, by: BarGlobalMock)

        def foo do
          @bar.bar()
        end
      end

  ## OTP21+

  Internally mockery is using tuple calls to pass additional data to its proxy module
  when mock is called. Tuple calls are disabled by default in OTP21+ and require additional
  compile flag to be reenabled.

      defmodule Foo do
        @compile :tuple_calls
        @bar Mockery.of("Bar")

        # ...
      end

  If you don't want to reenable tuple calls, there's also new macro-based alternative
  (for more information see `Mockery.Macro` module).
  """
  @spec of(
          mod :: module | elixir_module_as_string,
          opts :: [by: module | elixir_module_as_string]
        ) :: module | proxy_tuple
  def of(mod, opts \\ [])
      when is_atom(mod)
      when is_binary(mod) do
    case opts[:env] || mix_env() do
      :test ->
        do_proxy_tuple(mod, opts)

      _ ->
        to_mod(mod)
    end
  end

  # TODO remove in v3
  @deprecated """
  Mockery was not designed as solution for other libraries.
  It was a bad decision to try to workaround this.
  This approach was also extremely ugly and lacking all the advantages of Mockery
  """
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
  Function used to create mock in context of single test process.

  Mock created in test won't leak to another process (other test, spawned Task, GenServer...).
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
