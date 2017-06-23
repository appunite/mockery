defmodule MockeryTest do
  use ExUnit.Case, async: true

  describe "mock module defaults" do
    test "when arity == 0" do
      assert Dummy.fun1() == TestDummy.fun1()
      assert Dummy.fun2() == TestDummy.fun2()
    end

    test "when arity > 0" do
      assert Dummy.ar(1) == TestDummy.ar(1)
      assert Dummy.ar(1, "a") == TestDummy.ar(1, "a")
    end
  end

  describe "return/3" do
    test "by name (arity == 0)" do
      Mockery.return(Dummy, :fun1, "value1")

      assert TestDummy.fun1() == "value1"
    end

    test "by name and arity (arity == 0)" do
      Mockery.return(Dummy, [fun1: 0], "value2")

      assert TestDummy.fun1() == "value2"
    end

    test "by name (arity > 0)" do
      Mockery.return(Dummy, :ar, "value3")

      assert TestDummy.ar(1) == "value3"
      assert TestDummy.ar(1, 2) == "value3"
    end

    test "by name and arity (arity > 0)" do
      Mockery.return(Dummy, [ar: 1], "value4")

      assert TestDummy.ar(1) == "value4"
      refute TestDummy.ar(1, 2) == "value4"
    end
  end
end
