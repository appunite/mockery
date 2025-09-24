defmodule MockeryTest do
  use ExUnit.Case, async: true

  test "mock/3 with name (static mock)" do
    Mockery.mock(Dummy, :fun1, "value1")

    assert {"value1", _meta} = Process.get({Mockery, {Dummy, :fun1}})
  end

  test "mock/3 with name (dynamic mock)" do
    error_msg = """
    Dynamic mock requires [function: arity] syntax.

    Please use:
        mock(Dummy, [fun1: 0], fn(...) -> ... end)
    """

    assert_raise Mockery.Error, error_msg, fn -> Mockery.mock(Dummy, :fun1, fn -> :mock end) end
  end

  test "mock/3 with name and arity (static mock)" do
    Mockery.mock(Dummy, [fun1: 0], "value2")

    assert {"value2", _meta} = Process.get({Mockery, {Dummy, {:fun1, 0}}})
  end

  test "mock/3 with name and arity (dynamic mock)" do
    Mockery.mock(Dummy, [fun1: 0], fn -> :mock end)

    {fun, _meta} = Process.get({Mockery, {Dummy, {:fun1, 0}}})
    assert is_function(fun)
  end

  test "mock/3 with name and arity (dynamic mock with invalid arity)" do
    error_msg = """
    Dynamic mock must have the same arity as the original function

    Original arity: 0
    Mock arity: 1
    """

    assert_raise Mockery.Error, error_msg, fn ->
      Mockery.mock(Dummy, [fun1: 0], fn _ -> :mock end)
    end
  end

  test "mock/2 with name" do
    Mockery.mock(Dummy, :fun1)

    assert {:mocked, _meta} = Process.get({Mockery, {Dummy, :fun1}})
  end

  test "mock/2 with name and arity" do
    Mockery.mock(Dummy, fun1: 0)

    assert {:mocked, _meta} = Process.get({Mockery, {Dummy, {:fun1, 0}}})
  end

  test "chainable mock/2 and mock/3" do
    Dummy
    |> Mockery.mock(fun1: 0)
    |> Mockery.mock([ar: 1], "value")

    assert {:mocked, _meta} = Process.get({Mockery, {Dummy, {:fun1, 0}}})
    assert {"value", _meta} = Process.get({Mockery, {Dummy, {:ar, 1}}})
  end

  test "mock/2 with name raises error for non-existent function" do
    error_msg = "function Dummy.invalid/? is undefined or private"

    assert_raise Mockery.Error, error_msg, fn ->
      Mockery.mock(Dummy, :invalid)
    end
  end

  test "mock/2 with name and arity raises error for non-existent function" do
    error_msg = "function Dummy.fun1/1 is undefined or private"

    assert_raise Mockery.Error, error_msg, fn ->
      Mockery.mock(Dummy, fun1: 1)
    end
  end

  test "mock/2 with name raises error for non-existent module" do
    error_msg = "function Invalid.fun1/? is undefined or private"

    assert_raise Mockery.Error, error_msg, fn ->
      Mockery.mock(Invalid, :fun1)
    end
  end

  test "mock/2 with name and arity raises error for non-existent module" do
    error_msg = "function Invalid.fun1/1 is undefined or private"

    assert_raise Mockery.Error, error_msg, fn ->
      Mockery.mock(Invalid, fun1: 1)
    end
  end
end
