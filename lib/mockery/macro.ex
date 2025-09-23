defmodule Mockery.Macro do
  @moduledoc """
  Provides macros that enable mocking and assertions.

  This module should be included in your own modules with `use Mockery.Macro`.

  It imports the macros defined here and sets up compilation option to suppress warnings
  about **Mockery.Proxy.MacroProxy**.

  ## Example

      defmodule Foo do
        use Mockery.Macro

        def call_bar do
          mockable(Bar).bar()
        end
      end

  """

  @doc """
  Injects Mockery helper macros into the calling module.

  When you `use Mockery.Macro`, this macro:

  - Imports the macros from `Mockery.Macro` (`mockable/1`, `mockable/2`,
    and `defmock/2`).
  - When mockery is enabled (`config :mockery, :enable, true`),
    adds `@compile {:no_warn_undefined, Mockery.Proxy.MacroProxy}`
    so the compiler does not warn when `Mockery.Proxy.MacroProxy` is referenced.

  ## Options

  - `suppress_dialyzer_warnings: true | false` (default: `false`)

    See the ["Dialyzer"](#__using__/1-dialyzer) section for more information

  ## Example

      defmodule MyApp.Module do
        use Mockery.Macro

        ...
      end

  ## Dialyzer

  We recommend running Dialyzer in an environment where Mockery is not enabled
  (for example, `:dev`) so Dialyzer analyzes the original modules rather than the injected
  proxy module.

  If it is not possible to run Dialyzer in an environment with Mockery disabled, setting
  `use Mockery.Macro, suppress_dialyzer_warnings: true` will silence Dialyzer warnings that
  are caused by functions that use `mockable/2`. This works by adding per-function
  `@dialyzer {:nowarn_function, ...}` entries for functions that reference `mockable/2`.

  `:suppress_dialyzer_warnings` can also be enabled globally:

      # config/test.exs
      config :mockery, Mockery.Macro, suppress_dialyzer_warnings: true

  """
  @doc since: "2.3.3"
  defmacro __using__(opts \\ []) do
    if Application.get_env(:mockery, :enable),
      do: mockery_enabled_ast(opts),
      else: mockery_disabled_ast()
  end

  defp mockery_enabled_ast(opts) do
    quoted_defmocks_attr =
      quote do
        Module.register_attribute(__MODULE__, :defmocks, accumulate: true)
      end

    quoted_on_definition =
      quote do
        @on_definition unquote(__MODULE__)
      end

    on_definition =
      if Application.get_env(:mockery, Mockery.Macro, opts)[:suppress_dialyzer_warnings] do
        [quoted_defmocks_attr, quoted_on_definition]
      else
        []
      end

    quote do
      @compile {:no_warn_undefined, Mockery.Proxy.MacroProxy}
      unquote_splicing(on_definition)
      import unquote(__MODULE__)
    end
  end

  defp mockery_disabled_ast do
    quote do
      import unquote(__MODULE__)
    end
  end

  def __on_definition__(env, :defmacrop, name, _args, _guards, body) do
    Macro.prewalk(body, fn
      {:mockable, _, args} when is_list(args) -> throw(:mockery)
      ast -> ast
    end)
  catch
    :mockery ->
      Module.put_attribute(env.module, :defmocks, name)
  end

  def __on_definition__(env, kind, name, args, _guards, body) when kind in [:def, :defp] do
    defmocks = Module.get_attribute(env.module, :defmocks)

    # change acc to true if mockable or defmock is present in function
    Macro.prewalk(body, fn
      {:mockable, _, args} when is_list(args) ->
        throw(:mockery)

      {name, _, args} = ast when is_atom(name) and is_list(args) ->
        if name in defmocks, do: throw(:mockery)

        ast

      ast ->
        ast
    end)
  catch
    :mockery ->
      # tell dialyzer to shut up
      # @dialyzer {:nowarn_function, name: arity}
      Module.put_attribute(env.module, :dialyzer, {:nowarn_function, [{name, length(args)}]})
  end

  def __on_definition__(_env, _kind, _name, _args, _guards, _body) do
    :ok
  end

  @doc """
  Function used to prepare module for mocking/asserting.

  This macro enables mocking and assertions by setting up a proxy to the original module.
  When mocking is enabled via configuration (`config :mockery, enable: true`), it creates a proxy.
  Otherwise, it returns the original module unchanged.

  ## Examples
  #### Prepare for mocking

      defmodule Foo do
        use Mockery.Macro

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
        use Mockery.Macro

        def foo do
          mockable(Bar, by: BarGlobalMock).bar()
        end
      end

  > #### Potential issues {: .warning}
  >
  > Output of `mockable/2` macro should not be bind to variable or module attribute.
  > If it happens, you'll see a compilation warning at best, and in the worst case Mockery won't
  > work correctly.
  >
  > Examples of invalid usage:
  >     @var mockable(Foo)
  >
  >     var = mockable(Foo)
  """
  @doc since: "2.2.0"
  @spec mockable(
          mod :: module,
          opts :: [by: module]
        ) :: module
  defmacro mockable(mod, opts \\ []) do
    case Application.get_env(:mockery, :enable) || test_env?(opts, __CALLER__) do
      true ->
        quote do
          mocked_calls = Process.get(Mockery.MockableModule, [])
          Process.put(Mockery.MockableModule, [{unquote(mod), unquote(opts[:by])} | mocked_calls])

          Mockery.Proxy.MacroProxy
        end

      _ ->
        mod
    end
  end

  @warn "Mockery.Macro.mockable/2 based on Mix.env/0 is deprecated, " <>
          "please set `config :mockery, enable: true` in config/test.exs " <>
          "and recompile your project"

  @doc false
  def warn, do: @warn

  defp test_env?(opts, caller) do
    case opts[:env] || mix_env() do
      :test ->
        IO.warn(@warn, caller)

        true

      _ ->
        false
    end
  end

  @compile {:inline, mix_env: 0}
  defp mix_env do
    if function_exported?(Mix, :env, 0), do: Mix.env(), else: :prod
  end

  @doc """
  Defines a private macro that expands to `mockable/1` or `mockable/2`.

  ## Examples

      defmock :foo, Foo
      defmock :bar, Bar, by: GlobalMock

  These expand to:

      defmacrop foo do
        quote do: mockable(Foo)
      end

      defmacrop bar do
        quote do: mockable(Bar, by: GlobalMock)
      end

  This macro allows you to refactor code like this:

      def my_function do
        mockable(Bar, by: GlobalMock).function_call()
      end

  Into a cleaner form:

      defmock :bar, Bar, by: GlobalMock

      def my_function do
        bar().function_call()
      end

  """
  @doc since: "2.4.0"
  defmacro defmock(name, mod, opts \\ []) do
    quote do
      defmacrop unquote(name)() do
        mod = unquote(mod)
        opts = unquote(opts)

        quote do: mockable(unquote(mod), unquote(opts))
      end
    end
  end
end
