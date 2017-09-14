defmodule MockeryTest do
  use ExUnit.Case, async: true

  test "of/2 dev env (atom erlang mod)" do
    assert Mockery.of(:a, env: :dev) == :a
    assert Mockery.of(:a, by: Z, env: :dev) == :a
    assert Mockery.of(:a, by: "Z", env: :dev) == :a
  end

  test "of/2 test env (atom erlang mod)" do
    assert Mockery.of(:a) == {Mockery.Proxy, :a}
    assert Mockery.of(:a, by: Z) == {Z, :ok}
    assert Mockery.of(:a, by: "Z") == {Z, :ok}
  end

  test "of/2 dev env (atom elixir mod)" do
    assert Mockery.of(A, env: :dev) == A
    assert Mockery.of(A, by: Z, env: :dev) == A
    assert Mockery.of(A, by: "Z", env: :dev) == A
  end

  test "of/2 test env (atom elixir mod)" do
    assert Mockery.of(A) == {Mockery.Proxy, A}
    assert Mockery.of(A, by: Z) == {Z, :ok}
    assert Mockery.of(A, by: "Z") == {Z, :ok}
  end

  test "of/2 dev env (string elixir mod)" do
    assert Mockery.of("A", env: :dev) == A
    assert Mockery.of("A", by: Z, env: :dev) == A
    assert Mockery.of("A", by: "Z", env: :dev) == A
  end

  test "of/2 test env (string elixir mod)" do
    assert Mockery.of("A") == {Mockery.Proxy, A}
    assert Mockery.of("A", by: Z) == {Z, :ok}
    assert Mockery.of("A", by: "Z") == {Z, :ok}
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
end
