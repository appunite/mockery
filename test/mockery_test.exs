defmodule MockeryTest do
  use ExUnit.Case, async: true
  import Mockery

  defmodule TestDummy1 do
    use Mockery, module: Dummy
  end

  defmodule TestDummy2 do
    use Mockery, module: Dummy

    global_mock Dummy, [fun2: 0], do: 50
  end

  describe "defaults" do
    test "when arity == 0" do
      assert Dummy.fun1() == TestDummy1.fun1()
      assert Dummy.fun2() == TestDummy1.fun2()
    end

    test "when arity > 0" do
      assert Dummy.ar(1) == TestDummy1.ar(1)
      assert Dummy.ar(1, "a") == TestDummy1.ar(1, "a")
    end
  end

  describe "return/3" do
    test "with name (arity == 0)" do
      mock(Dummy, :fun1, "value1")

      assert TestDummy1.fun1() == "value1"
    end

    test "with name and arity (arity == 0)" do
      mock(Dummy, [fun1: 0], "value2")

      assert TestDummy1.fun1() == "value2"
    end

    test "with name (arity > 0)" do
      mock(Dummy, :ar, "value3")

      assert TestDummy1.ar(1) == "value3"
      assert TestDummy1.ar(1, 2) == "value3"
    end

    test "with name and arity (arity > 0)" do
      mock(Dummy, [ar: 1], "value4")

      assert TestDummy1.ar(1) == "value4"
      refute TestDummy1.ar(1, 2) == "value4"
    end
  end

  describe "global mock" do
    test "unchanged function" do
      assert TestDummy1.fun1() == 1
      assert TestDummy2.fun1() == 1
    end

    test "overriden function" do
      assert TestDummy1.fun2() == 2
      assert TestDummy2.fun2() == 50
    end

    test "overriden function respects mock" do
      mock(Dummy, :fun2, 100)

      assert TestDummy1.fun2() == 100
      assert TestDummy2.fun2() == 100
    end
  end
end
