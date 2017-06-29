defmodule Mockery.CoreTest do
  use ExUnit.Case, async: true
  alias Mockery.Core

  describe "of/2" do
    test "dev env" do
      assert Core.of(A, env: :dev) == A
      assert Core.of(A, by: Z, env: :dev) == A
    end

    test "test env" do
      assert Core.of(A) == {Mockery.Proxy, A}
      assert Core.of(A, by: Z) == {Z, :ok}
    end
  end

  describe "mock/3" do
    test "with name" do
      Core.mock(Dummy, :fun1, "value1")

      assert Process.get({{Mockery, :mock}, {Dummy, :fun1}}) == "value1"
    end

    test "with name and arity" do
      Core.mock(Dummy, [fun1: 0], "value2")

      assert Process.get({{Mockery, :mock}, {Dummy, {:fun1, 0}}}) == "value2"
    end
  end
end
