defmodule IntegrationTest.Tested do
  @moduledoc false

  use Mockery.Macro

  def fun3, do: mockable(IntegrationTest.Mocked).fun()
end
