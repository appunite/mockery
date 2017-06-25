defmodule Mockery do
  defdelegate of(mod, opts),         to: Mockery.Interface
  defdelegate mock(mod, fun, value), to: Mockery.Interface
end
