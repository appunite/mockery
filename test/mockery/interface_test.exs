defmodule Mockery.InterfaceTest do
  use ExUnit.Case, async: true
  alias Mockery.Interface

  describe "of/2" do
    test "dev env" do
      assert Interface.of(A, env: :dev) == A
      assert Interface.of(A, by: Z, env: :dev) == A
    end

    test "test env" do
      assert Interface.of(A) == {Mockery.Proxy, A}
      assert Interface.of(A, by: Z) == {Z, :ok}
    end
  end

  describe "mock/3" do
    test "with name" do
      Interface.mock(Dummy, :fun1, "value1")

      assert Process.get({:mockery, {Dummy, :fun1}}) == "value1"
    end

    test "with name and arity" do
      Interface.mock(Dummy, [fun1: 0], "value2")

      assert Process.get({:mockery, {Dummy, {:fun1, 0}}}) == "value2"
    end
  end
end
