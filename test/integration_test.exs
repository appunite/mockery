defmodule IntegrationTest do
  use ExUnit.Case, async: true
  import Mockery

  test "mocked module" do
    assert IntegrationTest.Mocked.fun() == 1
  end

  test "compile-time mode" do
    mock(IntegrationTest.Mocked, :fun, 2)

    assert IntegrationTest.Tested.fun1() == 2
  end

  test "test-env mode" do
    mock(IntegrationTest.Mocked, :fun, 3)

    assert IntegrationTest.Tested.fun2() == 3
  end

  test "macro version" do
    mock(IntegrationTest.Mocked, :fun, 4)

    assert IntegrationTest.Tested.fun3() == 4
  end
end
