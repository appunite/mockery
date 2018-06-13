defmodule IntegrationTest.Tested do
  @moduledoc false
  if :erlang.system_info(:otp_release) >= '21', do: @compile(:tuple_calls)

  @mock1 Mockery.of(IntegrationTest.Mocked)
  @mock2 Application.get_env(:mockery, :integration_test, IntegrationTest.Mocked)

  def fun1, do: @mock1.fun()
  def fun2, do: @mock2.fun()
end
