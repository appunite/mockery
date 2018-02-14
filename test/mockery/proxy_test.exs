defmodule Mockery.ProxyTest do
  use ExUnit.Case, async: true
  import Mockery

  alias Mockery.Utils

  # dummy.ex
  # defmodule Dummy do
  #   def fun1(), do: 1
  #   def fun2(), do: 2
  #   def ar(x), do: x
  #   def ar(x, y), do: [x,y]
  # end

  defmodule Tested1 do
    @dummy Mockery.of("Dummy")
    @crypto Mockery.of(:crypto)

    def fun1, do: @dummy.fun1()
    def ar(a), do: @dummy.ar(a)
    def ar(a, b), do: @dummy.ar(a, b)
    def undefined, do: @dummy.undefined()
    def hash(type, data), do: @crypto.hash(type, data)
  end

  # MAIN
  test "proxies to original elixir functions" do
    assert Tested1.fun1() == Dummy.fun1()
    assert Tested1.ar(1, 2) == Dummy.ar(1, 2)
  end

  test "proxies to original erlang functions" do
    assert Tested1.hash(:sha256, "test") == :crypto.hash(:sha256, "test")
  end

  test "allows elixir mocking" do
    mock(Dummy, :fun1, "mocked1")
    mock(Dummy, [ar: 2], "mocked2")

    assert Tested1.fun1() == "mocked1"
    assert Tested1.ar(1, 2) == "mocked2"
  end

  test "allows erlang mocking" do
    mock(:crypto, :hash, "hashed")

    assert Tested1.hash(:sha256, "test") == "hashed"
  end

  test "allows mocking with function of same arity" do
    mock(Dummy, [ar: 1], &to_string/1)

    assert Tested1.ar(1) == "1"
  end

  test "raise when mocking with function of different arity" do
    mock(Dummy, [ar: 2], &to_string/1)

    assert_raise Mockery.Error, "function used for mock should have same arity as original", fn ->
      Tested1.ar(1, 2)
    end
  end

  test "raise when function doesn't exist" do
    assert_raise Mockery.Error, "function Dummy.undefined/0 is undefined or private", fn ->
      Tested1.undefined()
    end
  end

  test "allow mocking with nil" do
    mock(Dummy, [ar: 2], nil)

    assert is_nil(Tested1.ar(1, 2))
  end

  test "allow mocking with false" do
    mock(Dummy, [ar: 2], false)

    assert Tested1.ar(1, 2) == false
  end

  # STORING CALLS
  test "function was not called" do
    assert Utils.get_calls(Dummy, :fun1) == []
  end

  test "function was called once (0 arity)" do
    _value = Tested1.fun1()

    assert Utils.get_calls(Dummy, :fun1) == [{0, []}]
  end

  test "function was called mutiple times (0 arity)" do
    Enum.each(1..3, fn _i -> Tested1.fun1() end)

    assert Utils.get_calls(Dummy, :fun1) == [{0, []}, {0, []}, {0, []}]
  end

  test "function was called once (positive arity)" do
    _value = Tested1.ar(1, "z")

    assert Utils.get_calls(Dummy, :ar) == [{2, [1, "z"]}]
  end

  test "function was called multiple times (positive arity)" do
    _value = Tested1.ar(1)
    _value = Tested1.ar(2, "a")
    _value = Tested1.ar(3)

    assert Utils.get_calls(Dummy, :ar) == [{1, [3]}, {2, [2, "a"]}, {1, [1]}]
  end

  test "different functions calls" do
    _value = Tested1.fun1()
    _value = Tested1.ar(1)

    assert Utils.get_calls(Dummy, :fun1) == [{0, []}]
    assert Utils.get_calls(Dummy, :ar) == [{1, [1]}]
  end

  defmodule Tested2 do
    defmodule DummyGlobalMock do
      def fun1, do: :fun1_global_mock
    end

    defmodule CryptoGlobalMock do
      def hash(_t, _d), do: :hash_global_mock
    end

    @dummy Mockery.of("Dummy", by: DummyGlobalMock)
    @crypto Mockery.of(:crypto, by: CryptoGlobalMock)

    def fun1, do: @dummy.fun1()
    def fun2, do: @dummy.fun2()
    def hash(type, data), do: @crypto.hash(type, data)
  end

  test "global mock for elixir module" do
    assert Tested2.fun1() == :fun1_global_mock
  end

  test "global mock for erlang module" do
    assert Tested2.hash(:sha256, "test") == :hash_global_mock
  end

  test "fallback to original when missing in global mock" do
    assert Tested2.fun2() == 2
  end

  defmodule Tested3 do
    defmodule DummyGlobalMock do
      def undefined, do: :undefined
    end

    @dummy Mockery.of("Dummy", by: DummyGlobalMock)

    def fun1, do: @dummy.fun1()
  end

  test "validates global_mock module" do
    assert_raise Mockery.Error,
                 ~r"""
                 Global mock \"Mockery.ProxyTest.Tested3.DummyGlobalMock\" exports \
                 functions unknown to \"Dummy\" module:
                 """,
                 fn -> Tested3.fun1() end
  end
end
