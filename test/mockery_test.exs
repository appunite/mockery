defmodule MockeryTest do
  use ExUnit.Case, async: true

  # describe "of/2" do
    test "dev env" do
      assert Mockery.of(A, env: :dev) == A
      assert Mockery.of(A, by: Z, env: :dev) == A
    end

    test "test env" do
      assert Mockery.of(A) == {Mockery.Proxy, A}
      assert Mockery.of(A, by: Z) == {Z, :ok}
    end
  # end

  # describe "mock/3" do
    test "with name" do
      Mockery.mock(Dummy, :fun1, "value1")

      assert Process.get({Mockery, {Dummy, :fun1}}) == "value1"
    end

    test "with name and arity" do
      Mockery.mock(Dummy, [fun1: 0], "value2")

      assert Process.get({Mockery, {Dummy, {:fun1, 0}}}) == "value2"
    end
  # end
end
