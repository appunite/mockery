defmodule MockeryTest do
  use ExUnit.Case, async: true

  test "of/2 dev env (atom erlang mod)" do
    assert Mockery.of(:a, env: :dev) == :a
  end

  test "of/2 test env (atom erlang mod)" do
    assert Mockery.of(:a) == {Mockery.Proxy, :a}
  end

  test "of/2 dev env (atom elixir mod)" do
    assert Mockery.of(A, env: :dev) == A
  end

  test "of/2 test env (atom elixir mod)" do
    assert Mockery.of(A) == {Mockery.Proxy, A}
  end

  test "of/2 dev env (string elixir mod)" do
    assert Mockery.of("A", env: :dev) == A
  end

  test "of/2 test env (string elixir mod)" do
    assert Mockery.of("A") == {Mockery.Proxy, A}
  end

  test "mock/3 with name" do
    Mockery.mock(Dummy, :fun1, "value1")

    assert Process.get({Mockery, {Dummy, :fun1}}) == "value1"
  end

  test "mock/3 with name and arity" do
    Mockery.mock(Dummy, [fun1: 0], "value2")

    assert Process.get({Mockery, {Dummy, {:fun1, 0}}}) == "value2"
  end

  test "mock/2 with name" do
    Mockery.mock(Dummy, :fun1)

    assert Process.get({Mockery, {Dummy, :fun1}}) == :mocked
  end

  test "mock/2 with name and arity" do
    Mockery.mock(Dummy, [fun1: 0])

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
