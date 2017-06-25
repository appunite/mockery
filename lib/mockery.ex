defmodule Mockery do
  alias Mockery.Utils

  def of(mod, opts) do
    if Mix.env == :test do
      Keyword.fetch!(opts, :through)
    else
      mod
    end
  end

  def mock(mod, fun, value) do
    Process.put(Utils.dict_mock_key(mod, fun), value)
  end
end
