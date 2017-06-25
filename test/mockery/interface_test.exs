defmodule Mockery.InterfaceTest do
  use ExUnit.Case, async: true
  import Mockery.Interface

  # dummy.ex
  # defmodule Dummy do
  #   def fun1(), do: 1
  #   def fun2(), do: 2
  #   def ar(x), do: x
  #   def ar(x, y), do: [x,y]
  # end

  defmodule TestDummy1 do
    use Mockery.Heritage, module: Dummy
  end

  defmodule TestDummy2 do
    use Mockery.Heritage, module: Dummy

    global_mock Dummy, [fun2: 0], do: 50
  end

  describe "mock/3" do
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

    test "allows using function of same arity" do
      mock(Dummy, :ar, &to_string/1)

      assert TestDummy1.ar(200) == "200"
    end

    test "test raise on function with bad arity" do
      mock(Dummy, :ar, &to_string/1)

      assert_raise(
        Mockery.Error,
        "function used for mock should have same arity as original",
        fn -> TestDummy1.ar(1, 2) end
      )
    end
  end
end
