defmodule Mockery.Copy do
  def new(mod, opts \\ []) do
    case Application.get_env(:mockery, :enable) do
      true ->
        compile_copy(mod, opts)

      _ ->
        mod
    end
  end

  defp compile_copy(mod, opts) do
    copy_name = opts[:name] || Module.concat([mod, "Copy#{System.unique_integer([:positive])}"])
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
