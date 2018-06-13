defmodule Mockery.Proxy.MacroProxy do
  @moduledoc false

  def unquote(:"$handle_undefined_function")(name, args) do
    {mod, by} = Process.get(Mockery.MockableModule)
    Process.delete(Mockery.MockableModule)

    Mockery.Proxy.do_proxy(mod, name, args, by)
  end
end
