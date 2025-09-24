defmodule Mockery do
  @moduledoc """
  Provides core mocking functionality for Elixir tests.

  This module offers tools to create and manage mocks within the
  context of individual test processes. Mocks created here are isolated and
  will not affect other processes, making them safe for concurrent and
  asynchronous testing.

  ## Using Mockery in your tests

  By adding `use Mockery` in your test modules, you automatically import several useful modules and functions:

  - Core Mockery function `mock/3`
  - Assertion helpers from `Mockery.Assertions` ([`assert_called!/3`](Mockery.Assertions.html#assert_called!/3), [`refute_called!/3`](Mockery.Assertions.html#refute_called!/3))
  - History control functions from `Mockery.History` ([`enable_history/0`](Mockery.History.html#enable_history/0), [`disable_history/0`](Mockery.History.html#disable_history/0))

  Example usage:

      defmodule MyApp.User do
        def greet, do: "Hello, User!"
      end

      defmodule MyApp.Greeter do
        use Mockery.Macro

        def greet_user do
          mockable(MyApp.User).greet()
        end
      end

      defmodule MyApp.GreeterTest do
        use ExUnit.Case, async: true
        use Mockery

        test "mock greet/0 from MyApp.User" do
          mock(MyApp.User, [greet: 0], "Hello, Mocked User!")

          assert MyApp.Greeter.greet_user() == "Hello, Mocked User!"
          assert_called! MyApp.User, :greet, args: [], times: 1
        end
      end

  """
  alias Mockery.Utils

  defmacro __using__(_opts) do
    quote do
      import Mockery
      import Mockery.Assertions
      import Mockery.History, only: [enable_history: 0, enable_history: 1, disable_history: 0]
    end
  end

  # TODO remove in v3
  @deprecated """
  Tuple calls won't be officially supported in Mockery v3.
  Please migrate to the new macro-based alternative available in `Mockery.Macro`
  """
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

  @typedoc "Function name (an atom identifying the function)."
  @type function_name :: atom()

  @typedoc """
  A static mock return value

  Any Elixir term except functions.
  """
  @type static_mock_value :: term()

  @typedoc """
  A dynamic mock function.

  This is a function invoked when the mocked function is called.
  The dynamic mock must accept the same arity as the original function
  being mocked and its return value is used as the mock result.
  """
  @type dynamic_mock :: fun()

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
  @spec mock(module(), function_name(), static_mock_value()) :: module()
  @spec mock(module(), [{function_name(), arity()}], static_mock_value()) :: module()
  @spec mock(module(), [{function_name(), arity()}], dynamic_mock()) :: module()

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
