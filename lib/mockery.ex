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

  # TODO remove in v3
  @deprecated """
  The `of` function is deprecated. Tuple calls won't be officially supported in Mockery v3.
  Please migrate to the new macro-based alternative available in `Mockery.Macro`.
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
