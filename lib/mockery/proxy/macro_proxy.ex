defmodule Mockery.Proxy.MacroProxy do
  @moduledoc false

  alias Mockery.Proxy

  def unquote(:"$handle_undefined_function")(name, args) do
    {mod, by} = Process.get(Mockery.MockableModule)
    Process.delete(Mockery.MockableModule)

    Proxy.do_proxy(mod, name, args, by)
  end
end
