defmodule IntegrationTest do
  use ExUnit.Case, async: true
  import Mockery

  test "mocked module" do
    assert IntegrationTest.Mocked.fun() == 1
  end

  test "mockable" do
    mock(IntegrationTest.Mocked, :fun, 2)

    assert IntegrationTest.Tested.fun1() == 2
  end

  test "defmock" do
    mock(IntegrationTest.Mocked, :fun, 3)

    assert IntegrationTest.Tested.fun2() == 3
  end
end
