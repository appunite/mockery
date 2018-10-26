defmodule Mockery.Macro do
  @moduledoc """
  Alternative macro-based way to prepare module for mocking/asserting.
  """

  @doc """
  Function used to prepare module for mocking/asserting.

  For Mix.env other than :test it returns the first argument unchanged.
  If Mix.env equal :test it creates a proxy to the original module.
  When Mix is missing it assumes that env is :prod.

  ## Examples
  #### Prepare for mocking

      defmodule Foo do
        import Mockery.Macro

        def foo do
          mockable(Bar).bar()
        end
      end

  #### Prepare for mocking with global mock

      # test/support/global_mocks/bar.ex
      defmodule BarGlobalMock do
        def bar, do: :mocked
      end

      # lib/foo.ex
      defmodule Foo do
        import Mockery.Macro

        def foo do
          mockable(Bar, by: BarGlobalMock).bar()
        end
      end

  ## Mockery.of/2 comparison

    * It's based on macro and process dictionary instead of on tuple calls. (Tuple calls
    are disabled by default in OTP21+ and require additional compile flag to be reenabled)
    * It doesn't support passing module names as a string as it don't create unwanted compile-time
    dependencies between modules

  ## Potential issues

  Output of `mockable/2` macro should not be bind to variable or module attribute.
  If it happens, you'll see a compilation warning at best, and in the worst case Mockery won't
  work correctly.

  """
  @spec mockable(
          mod :: module,
          opts :: [by: module]
        ) :: module
  defmacro mockable(mod, opts \\ []) do
    case opts[:env] || mix_env() do
      :test ->
        quote do
          mocked_calls = Process.get(Mockery.MockableModule, [])
          Process.put(Mockery.MockableModule, [{unquote(mod), unquote(opts[:by])} | mocked_calls])

          Mockery.Proxy.MacroProxy
        end

      _ ->
        mod
    end
  end

  @compile {:inline, mix_env: 0}
  defp mix_env do
    if function_exported?(Mix, :env, 0), do: Mix.env(), else: :prod
  end
end
