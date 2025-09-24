defmodule MockeryTest do
  use ExUnit.Case, async: true

  test "mock/3 with name (static mock)" do
    Mockery.mock(Dummy, :fun1, "value1")

    assert Process.get({Mockery, {Dummy, :fun1}}) == "value1"
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

    assert Process.get({Mockery, {Dummy, {:fun1, 0}}}) == "value2"
  end

  test "mock/3 with name and arity (dynamic mock)" do
    Mockery.mock(Dummy, [fun1: 0], fn -> :mock end)

    assert is_function(Process.get({Mockery, {Dummy, {:fun1, 0}}}))
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

    assert Process.get({Mockery, {Dummy, :fun1}}) == :mocked
  end

  test "mock/2 with name and arity" do
    Mockery.mock(Dummy, fun1: 0)

    assert Process.get({Mockery, {Dummy, {:fun1, 0}}}) == :mocked
  end

  test "chainable mock/2 and mock/3" do
    Dummy
    |> Mockery.mock(fun1: 0)
    |> Mockery.mock([fun2: 1], "value")

    assert Process.get({Mockery, {Dummy, {:fun1, 0}}}) == :mocked
    assert Process.get({Mockery, {Dummy, {:fun2, 1}}}) == "value"
  end
end
