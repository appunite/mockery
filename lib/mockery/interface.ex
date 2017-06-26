defmodule Mockery.Interface do
  alias Mockery.Utils

  def of(mod, opts \\ []) do
    env = opts[:env] || Mix.env

    if env == :test do
      Keyword.get(opts, :by, {Mockery.Heritage, mod})
    else
      mod
    end
  end

  def mock(mod, fun, value) do
    Process.put(Utils.dict_mock_key(mod, fun), value)
  end
end
