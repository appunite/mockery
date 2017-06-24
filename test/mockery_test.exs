defmodule MockeryTest do
  use ExUnit.Case, async: true

  defmodule TestDummy1 do
    use Mockery, module: Dummy
  end

  defmodule TestDummy2 do
    use Mockery, module: Dummy

    def fun2(), do: 3
    def ar(x), do: x + 1
  end

  describe "mock module defaults" do
    test "when arity == 0" do
      assert Dummy.fun1() == TestDummy1.fun1()
      assert Dummy.fun2() == TestDummy1.fun2()
    end

    test "when arity > 0" do
      assert Dummy.ar(1) == TestDummy1.ar(1)
      assert Dummy.ar(1, "a") == TestDummy1.ar(1, "a")
    end
  end

  describe "mock module defaults override" do
    test "unchanged function" do
      assert TestDummy1.fun1() == 1
      assert TestDummy2.fun1() == 1
    end

    test "overriden function" do
      assert TestDummy1.fun2() == 2
      assert TestDummy2.fun2() == 3
    end
  end

  describe "return/3" do
    test "by name (arity == 0)" do
      Mockery.return(Dummy, :fun1, "value1")

      assert TestDummy1.fun1() == "value1"
    end

    test "by name and arity (arity == 0)" do
      Mockery.return(Dummy, [fun1: 0], "value2")

      assert TestDummy1.fun1() == "value2"
    end

    test "by name (arity > 0)" do
      Mockery.return(Dummy, :ar, "value3")

      assert TestDummy1.ar(1) == "value3"
      assert TestDummy1.ar(1, 2) == "value3"
    end

    test "by name and arity (arity > 0)" do
      Mockery.return(Dummy, [ar: 1], "value4")

      assert TestDummy1.ar(1) == "value4"
      refute TestDummy1.ar(1, 2) == "value4"
    end
  end
end
