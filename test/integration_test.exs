defmodule IntegrationTest do
  use ExUnit.Case, async: true
  import Mockery

  test "mocked module" do
    assert IntegrationTest.Mocked.fun() == 1
  end

  test "macro version" do
    mock(IntegrationTest.Mocked, :fun, 4)

    assert IntegrationTest.Tested.fun3() == 4
  end
end
