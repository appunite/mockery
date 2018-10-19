defmodule Mockery.Proxy.MacroProxyTest do
  use ExUnit.Case, async: true
  import Mockery
  import Mockery.Assertions
  import Mockery.Macro

  alias Mockery.Proxy.MacroProxy
  alias Mockery.Utils

  # dummy.ex
  # defmodule Dummy do
  #   def fun1(), do: 1
  #   def fun2(), do: 2
  #   def ar(x), do: x
  #   def ar(x, y), do: [x,y]
  # end

  defmodule DummyGlobalMock do
    def fun1, do: :fun1_global_mock
  end

  defmodule CryptoGlobalMock do
    def hash(_t, _d), do: :hash_global_mock
  end

  defmodule DummyGlobalMock2 do
    def undefined, do: :undefined
  end

  ############### MAIN ###############
  test "proxies to original elixir functions" do
    assert mockable(Dummy).fun1() == Dummy.fun1()
    assert mockable(Dummy).ar(1, 2) == Dummy.ar(1, 2)
  end

  test "proxies to original erlang functions" do
    assert mockable(:crypto).hash(:sha256, "test") == :crypto.hash(:sha256, "test")
  end

  test "allows elixir mocking" do
    mock(Dummy, :fun1, "mocked1")
    mock(Dummy, [ar: 2], "mocked2")

    assert mockable(Dummy).fun1() == "mocked1"
    assert mockable(Dummy).ar(1, 2) == "mocked2"
  end

  test "allows erlang mocking" do
    mock(:crypto, :hash, "hashed")

    assert mockable(:crypto).hash(:sha256, "test") == "hashed"
  end

  test "allows mocking with function of same arity" do
    mock(Dummy, [ar: 1], &to_string/1)

    assert mockable(Dummy).ar(1) == "1"
  end

  test "raise when mocking with function of different arity" do
    mock(Dummy, [ar: 2], &to_string/1)

    assert_raise Mockery.Error,
                 "function used for mock should have same arity as original",
                 fn ->
                   mockable(Dummy).ar(1, 2)
                 end
  end

  test "raise when function doesn't exist" do
    assert_raise Mockery.Error, "function Dummy.undefined/0 is undefined or private", fn ->
      mockable(Dummy).undefined()
    end
  end

  test "allow mocking with nil" do
    mock(Dummy, [ar: 2], nil)

    assert is_nil(mockable(Dummy).ar(1, 2))
  end

  test "allow mocking with false" do
    mock(Dummy, [ar: 2], false)

    assert mockable(Dummy).ar(1, 2) == false
  end

  ############### STORING CALLS ###############
  test "function was not called" do
    assert Utils.get_calls(Dummy, :fun1) == []
  end

  test "function was called once (0 arity)" do
    _value = mockable(Dummy).fun1()

    assert Utils.get_calls(Dummy, :fun1) == [{0, []}]
  end

  test "function was called mutiple times (0 arity)" do
    Enum.each(1..3, fn _i -> mockable(Dummy).fun1() end)

    assert Utils.get_calls(Dummy, :fun1) == [{0, []}, {0, []}, {0, []}]
  end

  test "function was called once (positive arity)" do
    _value = mockable(Dummy).ar(1, "z")

    assert Utils.get_calls(Dummy, :ar) == [{2, [1, "z"]}]
  end

  test "function was called multiple times (positive arity)" do
    _value = mockable(Dummy).ar(1)
    _value = mockable(Dummy).ar(2, "a")
    _value = mockable(Dummy).ar(3)

    assert Utils.get_calls(Dummy, :ar) == [{1, [3]}, {2, [2, "a"]}, {1, [1]}]
  end

  test "different functions calls" do
    _value = mockable(Dummy).fun1()
    _value = mockable(Dummy).ar(1)

    assert Utils.get_calls(Dummy, :fun1) == [{0, []}]
    assert Utils.get_calls(Dummy, :ar) == [{1, [1]}]
  end

  ############### GLOBAL ###############
  test "global mock for elixir module" do
    assert mockable(Dummy, by: DummyGlobalMock).fun1() == :fun1_global_mock
  end

  test "global mock for erlang module" do
    assert mockable(:crypto, by: CryptoGlobalMock).hash(:sha256, "test") == :hash_global_mock
  end

  test "fallback to original when missing in global mock" do
    assert mockable(Dummy, by: DummyGlobalMock).fun2() == 2
  end

  ############### GLOBAL VALIDATION ###############
  test "validates global_mock module" do
    assert_raise Mockery.Error,
                 ~r"""
                 Global mock \"Mockery.Proxy.MacroProxyTest.DummyGlobalMock2\" exports \
                 functions unknown to \"Dummy\" module:
                 """,
                 fn -> mockable(Dummy, by: DummyGlobalMock2).fun1() end
  end

  ############### INVALID USAGE ###############
  defmodule Macro.InvalidUsage do
    import Mockery.Macro
    @invalid mockable(Dummy)

    def invalid, do: @invalid.fun1()
  end

  # credo:disable-for-lines:7 Credo.Check.Design.AliasUsage
  test "raise if mockable/2 macro wasn't used directly in code" do
    assert_raise(
      Mockery.Error,
      ~r"Mockery.Macro.mockable/2 needs to be invoked directly in other function.",
      fn -> Macro.InvalidUsage.invalid() end
    )
  end

  ############### NESTED CALLS/PIPES ###############
  test "handles piped calls" do
    Dummy
    |> mock([fun1: 0], fn -> :it_worked end)
    |> mock(ar: 1)

    # credo:disable-for-lines:2 Credo.Check.Readability.SinglePipe
    mockable(Dummy).fun1()
    |> mockable(Dummy).ar()

    assert_called(Dummy, :fun1, [])
    assert_called(Dummy, :ar, [:it_worked])
  end

  test "handles nested calls" do
    Dummy
    |> mock([fun1: 0], fn -> :it_worked end)
    |> mock(ar: 1)

    mockable(Dummy).ar(mockable(Dummy).fun1())

    assert_called(Dummy, :fun1, [])
    assert_called(Dummy, :ar, [:it_worked])
  end

  # TODO remove in v3
  test "preserves backward compatibility" do
    _ = Process.put(Mockery.MockableModule, {Dummy, nil})
    MacroProxy.fun1()

    assert_called(Dummy, :fun1, [])
  end
end
