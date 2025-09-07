defmodule IntegrationTest.Tested do
  @moduledoc false

  use Mockery.Macro

  def fun1, do: mockable(IntegrationTest.Mocked).fun()

  defmock :mock, IntegrationTest.Mocked
  def fun2, do: mock().fun()
end
