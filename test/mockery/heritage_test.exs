defmodule Mockery.HeritageTest do
  use ExUnit.Case, async: true
  import Mockery

  alias Mockery.Utils

  # dummy.ex
  # defmodule Dummy do
  #   def fun1(), do: 1
  #   def fun2(), do: 2
  #   def fun3(), do: 3
  #   def fun4(), do: 4
  #   def ar(x), do: x
  #   def ar(x, y), do: [x,y]
  # end

  defmodule TestDummy do
    use Mockery.Heritage, module: Dummy

    mock [fun2: 0] do
      "global mock"
    end

    mock [fun3: 0] do
      fn-> "global mock as function" end
    end

    mock [fun4: 0] do
      &to_string/1
    end
  end

  defmodule Tested do
    @dummy Mockery.of(Dummy, by: TestDummy)

    def fun1, do: @dummy.fun1()
    def fun2, do: @dummy.fun2()
    def fun3, do: @dummy.fun3()
    def fun4, do: @dummy.fun4()
    def ar(a), do: @dummy.ar(a)
    def ar(a, b), do: @dummy.ar(a, b)
    def undefined(), do: @dummy.undefined()
  end

  # MAIN
  test "proxies to original functions" do
    assert Tested.fun1() == Dummy.fun1()
    assert Tested.ar(1, 2) == Dummy.ar(1, 2)
  end

  test "allows mocking" do
    mock(Dummy, :fun1, "mocked1")
    mock(Dummy, [ar: 2], "mocked2")

    assert Tested.fun1() == "mocked1"
    assert Tested.ar(1, 2) == "mocked2"
  end

  test "allows mocking with function of same arity" do
    mock(Dummy, :ar, &to_string/1)

    assert Tested.ar(1) == "1"
  end

  test "raise when mocking with function of different arity" do
    mock(Dummy, :ar, &to_string/1)

    assert_raise(
      Mockery.Error,
      "function used for mock should have same arity as original",
      fn -> Tested.ar(1, 2) end
    )
  end

  test "allows global mocks" do
    assert Tested.fun2() == "global mock"
  end

  test "allows global mocks as function of same arity" do
    assert Tested.fun3() == "global mock as function"
  end

  test "raises on global mock as function with dirrerent arity" do
    assert_raise(
      Mockery.Error,
      "function used for mock should have same arity as original",
      fn -> Tested.fun4() end
    )
  end

  test "respects local mocks overriding global mocks" do
    mock(Dummy, :fun2, "local mock")

    assert Tested.fun2() == "local mock"
  end

  test "raises when function doesn't exist" do
    assert_raise(
      Mockery.Error,
      "function Mockery.HeritageTest.TestDummy.undefined/0 is undefined or private",
      fn -> Tested.undefined() end
    )
  end

  test "allow mocking with nil" do
    mock(Dummy, [ar: 2], nil)

    assert is_nil Tested.ar(1, 2)
  end

  test "allow mocking with false" do
    mock(Dummy, [ar: 2], false)

    assert Tested.ar(1, 2) == false
  end

  # STORING CALLS
  test "function was not called" do
    assert Utils.get_calls(Dummy, :fun1) == []
  end

  test "function was called once (0 arity)" do
    _value = Tested.fun1()

    assert Utils.get_calls(Dummy, :fun1) == [{0, []}]
  end

  test "function was called mutiple times (0 arity)" do
    Enum.each(1..3, fn(_i) -> Tested.fun1() end)

    assert Utils.get_calls(Dummy, :fun1) == [{0, []}, {0, []}, {0, []}]
  end

  test "function was called once (positive arity)" do
    _value = Tested.ar(1, "z")

    assert Utils.get_calls(Dummy, :ar) == [{2, [1, "z"]}]
  end

  test "function was called multiple times (positive arity)" do
    _value = Tested.ar(1)
    _value = Tested.ar(2, "a")
    _value = Tested.ar(3)

    assert Utils.get_calls(Dummy, :ar) == [{1, [3]}, {2, [2, "a"]}, {1, [1]}]
  end

  test "different functions calls" do
    _value = Tested.fun1()
    _value = Tested.ar(1)

    assert Utils.get_calls(Dummy, :fun1) == [{0, []}]
    assert Utils.get_calls(Dummy, :ar) == [{1, [1]}]
  end
end
