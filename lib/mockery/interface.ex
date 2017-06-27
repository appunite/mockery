defmodule Mockery.Interface do
  alias Mockery.Utils

  def of(mod, opts \\ []) do
    env = opts[:env] || Mix.env

    cond do
      env != :test ->
        mod
      by = Keyword.get(opts, :by) ->
        by
      :else ->
        {Mockery.Proxy, mod}
    end
  end

  def mock(mod, fun, value) do
    Process.put(Utils.dict_mock_key(mod, fun), value)
  end
end
