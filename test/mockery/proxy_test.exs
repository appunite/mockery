defmodule Mockery.ProxyTest do
  use ExUnit.Case, async: true
  import Mockery

  # dummy.ex
  # defmodule Dummy do
  #   def fun1(), do: 1
  #   def fun2(), do: 2
  #   def ar(x), do: x
  #   def ar(x, y), do: [x,y]
  # end

  defmodule Tested do
    @dummy Mockery.of(Dummy)

    def fun1, do: @dummy.fun1()
    def ar(a), do: @dummy.ar(a)
    def ar(a, b), do: @dummy.ar(a, b)
    def undefined(), do: @dummy.undefined()
  end

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

  test "raise when function doesn't exist" do
    assert_raise(
      Mockery.Error,
      "function Dummy.undefined/0 is undefined or private",
      fn -> Tested.undefined() end
    )
  end
end
