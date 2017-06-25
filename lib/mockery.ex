defmodule Mockery do
  alias Mockery.Utils

  def mock(mod, fun, value) do
    Process.put(Utils.dict_mock_key(mod, fun), value)
  end
end
