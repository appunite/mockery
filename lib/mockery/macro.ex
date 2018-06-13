defmodule Mockery.Macro do
  @moduledoc """
  Contains alternative macro-based way to prepare module for mocking.
  """

  defmacro __using__(_opts) do
    env = mix_env()

    quote do
      import Mockery.Macro, only: [mockable: 2]

      # disables dialyzer warnings about missing function in test env
      if unquote(env) == :test, do: @dialyzer(:nowarn_missing_function)
    end
  end

  @doc """
  Function used to prepare module for mocking.

  For Mix.env other than :test it returns the first argument unchanged.
  For Mix.env == :test it creates a proxy to the original module.
  When Mix is missing it assumes that env is :prod

  ## Example

      defmodule Foo do
        import Mockery.Macro

        def foo do
          mockable(Bar).bar()
        end
      end

  """
  defmacro mockable(mod, opts) when is_atom(mod) do
    case opts[:env] || mix_env() do
      :test ->
        quote do
          Process.put(Mockery.MockableModule, {unquote(mod), unquote(opts[:by])})

          Mockery.MacroProxy
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
