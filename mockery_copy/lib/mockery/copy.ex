defmodule Mockery.Copy do
  @moduledoc """
  Helper to produce a runtime copy of a module that delegates through Mockery.

  Use `of/2` to obtain either the original module (when Mockery is disabled)
  or a generated module that forwards calls through `Mockery.Proxy`.
  """

  @doc """
  Prepare `mod` for use with Mockery and return either the original module
  or a generated proxy module.

  ## Behavior
  - When mockery is enabled (`config :mockery, enable: true`), this function
    dynamically creates a new module which defines the same exported functions
    as `mod`. Each function delegates to `Mockery.Proxy`
    allowing Mockery to intercept, record, or reroute calls.
  - If `:mockery, :enable` config is not `true`, the original `mod` is returned
    unchanged.

  ## Options
  - `:name` - an explicit atom to use as the generated module name. If not
    provided, a unique module name is generated automatically.
  - `:by` - an optional module used as a global mock provider.

  ## Notes
  - The generated module exports the same functions as the original module,
    excluding `module_info/0`, `module_info/1` and `__info__/1`.

  ## Examples

      # Create a copy with an automatically generated name
      copy = Mockery.Copy.of(MyApp.Foo)

      # Create a copy with explicit name and a global mock
      copy = Mockery.Copy.of(MyApp.Foo, name: MyApp.FooMock, by: MyApp.FooGlobalMock)

  """
  @spec of(
          mod :: module,
          opts :: [name: module, by: module]
        ) :: module
  def of(mod, opts \\ []) do
    case Application.get_env(:mockery, :enable) do
      true ->
        compile_copy(mod, opts)

      _ ->
        mod
    end
  end

  defp compile_copy(mod, opts) do
    copy_name =
      opts[:name] ||
        Module.concat([mod, "Mockery", "Mockable#{System.unique_integer([:positive])}"])

    by = opts[:by]

    funs = mod.module_info()[:exports] -- [module_info: 0, module_info: 1, __info__: 1]

    quoted_funs =
      for {name, arity} <- funs do
        args = Macro.generate_arguments(arity, copy_name)

        quote do
          def unquote(name)(unquote_splicing(args)) do
            Mockery.Proxy.do_proxy(unquote(mod), unquote(name), unquote(args), unquote(by))
          end
        end
      end

    location = Macro.Env.location(__ENV__)
    {:module, module_name, _, _} = Module.create(copy_name, quoted_funs, location)

    module_name
  end
end
