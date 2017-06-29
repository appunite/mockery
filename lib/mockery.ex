defmodule Mockery do
  defdelegate of(mod, opts \\ []),   to: Mockery.Core
  defdelegate mock(mod, fun, value), to: Mockery.Core
end
