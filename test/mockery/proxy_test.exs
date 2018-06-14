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

  defmodule TupleCall.Tested1 do
    if :erlang.system_info(:otp_release) >= '21', do: @compile(:tuple_calls)

    @dummy Mockery.of("Dummy")
    @crypto Mockery.of(:crypto)

    def fun1, do: @dummy.fun1()
    def ar(a), do: @dummy.ar(a)
    def ar(a, b), do: @dummy.ar(a, b)
    def undefined, do: @dummy.undefined()
    def hash(type, data), do: @crypto.hash(type, data)
  end

  defmodule Macro.Tested1 do
    import Mockery.Macro

    def fun1, do: mockable(Dummy).fun1()
    def ar(a), do: mockable(Dummy).ar(a)
    def ar(a, b), do: mockable(Dummy).ar(a, b)
    def undefined, do: mockable(Dummy).undefined()
    def hash(type, data), do: mockable(:crypto).hash(type, data)
  end

  defmodule TupleCall.Tested2 do
    if :erlang.system_info(:otp_release) >= '21', do: @compile(:tuple_calls)

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

  defmodule Macro.Tested2 do
    import Mockery.Macro

    defmodule DummyGlobalMock do
      def fun1, do: :fun1_global_mock
    end

    defmodule CryptoGlobalMock do
      def hash(_t, _d), do: :hash_global_mock
    end

    def fun1, do: mockable(Dummy, by: DummyGlobalMock).fun1()
    def fun2, do: mockable(Dummy, by: DummyGlobalMock).fun2()
    def hash(type, data), do: mockable(:crypto, by: CryptoGlobalMock).hash(type, data)
  end

  defmodule TupleCall.Tested3 do
    if :erlang.system_info(:otp_release) >= '21', do: @compile(:tuple_calls)

    defmodule DummyGlobalMock do
      def undefined, do: :undefined
    end

    @dummy Mockery.of("Dummy", by: DummyGlobalMock)

    def fun1, do: @dummy.fun1()
  end

  defmodule Macro.Tested3 do
    import Mockery.Macro

    defmodule DummyGlobalMock do
      def undefined, do: :undefined
    end

    def fun1, do: mockable(Dummy, by: DummyGlobalMock).fun1()
  end

  Enum.each(["TupleCall", "Macro"], fn type ->
    tested1 = Module.concat([__MODULE__, type, Tested1])
    tested2 = Module.concat([__MODULE__, type, Tested2])
    tested3 = Module.concat([__MODULE__, type, Tested3])

    describe "#{type}-based Mockery.Proxy" do
      ############### MAIN ###############
      test "proxies to original elixir functions" do
        assert unquote(tested1).fun1() == Dummy.fun1()
        assert unquote(tested1).ar(1, 2) == Dummy.ar(1, 2)
      end

      test "proxies to original erlang functions" do
        assert unquote(tested1).hash(:sha256, "test") == :crypto.hash(:sha256, "test")
      end

      test "allows elixir mocking" do
        mock(Dummy, :fun1, "mocked1")
        mock(Dummy, [ar: 2], "mocked2")

        assert unquote(tested1).fun1() == "mocked1"
        assert unquote(tested1).ar(1, 2) == "mocked2"
      end

      test "allows erlang mocking" do
        mock(:crypto, :hash, "hashed")

        assert unquote(tested1).hash(:sha256, "test") == "hashed"
      end

      test "allows mocking with function of same arity" do
        mock(Dummy, [ar: 1], &to_string/1)

        assert unquote(tested1).ar(1) == "1"
      end

      test "raise when mocking with function of different arity" do
        mock(Dummy, [ar: 2], &to_string/1)

        assert_raise Mockery.Error,
                     "function used for mock should have same arity as original",
                     fn ->
                       unquote(tested1).ar(1, 2)
                     end
      end

      test "raise when function doesn't exist" do
        assert_raise Mockery.Error, "function Dummy.undefined/0 is undefined or private", fn ->
          unquote(tested1).undefined()
        end
      end

      test "allow mocking with nil" do
        mock(Dummy, [ar: 2], nil)

        assert is_nil(unquote(tested1).ar(1, 2))
      end

      test "allow mocking with false" do
        mock(Dummy, [ar: 2], false)

        assert unquote(tested1).ar(1, 2) == false
      end

      # STORING CALLS
      test "function was not called" do
        assert Utils.get_calls(Dummy, :fun1) == []
      end

      test "function was called once (0 arity)" do
        _value = unquote(tested1).fun1()

        assert Utils.get_calls(Dummy, :fun1) == [{0, []}]
      end

      test "function was called mutiple times (0 arity)" do
        Enum.each(1..3, fn _i -> unquote(tested1).fun1() end)

        assert Utils.get_calls(Dummy, :fun1) == [{0, []}, {0, []}, {0, []}]
      end

      test "function was called once (positive arity)" do
        _value = unquote(tested1).ar(1, "z")

        assert Utils.get_calls(Dummy, :ar) == [{2, [1, "z"]}]
      end

      test "function was called multiple times (positive arity)" do
        _value = unquote(tested1).ar(1)
        _value = unquote(tested1).ar(2, "a")
        _value = unquote(tested1).ar(3)

        assert Utils.get_calls(Dummy, :ar) == [{1, [3]}, {2, [2, "a"]}, {1, [1]}]
      end

      test "different functions calls" do
        _value = unquote(tested1).fun1()
        _value = unquote(tested1).ar(1)

        assert Utils.get_calls(Dummy, :fun1) == [{0, []}]
        assert Utils.get_calls(Dummy, :ar) == [{1, [1]}]
      end

      ############### GLOBAL ###############
      test "global mock for elixir module" do
        assert unquote(tested2).fun1() == :fun1_global_mock
      end

      test "global mock for erlang module" do
        assert unquote(tested2).hash(:sha256, "test") == :hash_global_mock
      end

      test "fallback to original when missing in global mock" do
        assert unquote(tested2).fun2() == 2
      end

      ############### GLOBAL VALIDATION ###############
      test "validates global_mock module" do
        assert_raise Mockery.Error,
                     ~r"""
                     Global mock \"Mockery.ProxyTest.#{unquote(type)}.Tested3.DummyGlobalMock\" exports \
                     functions unknown to \"Dummy\" module:
                     """,
                     fn -> unquote(tested3).fun1() end
      end
    end
  end)

  defmodule Macro.Tested4 do
    import Mockery.Macro
    @invalid mockable(Dummy)

    def invalid, do: @invalid.fun1()
  end

  # credo:disable-for-lines:7 Credo.Check.Design.AliasUsage
  test "raise if mockable/2 macro wasn't used directly in code" do
    assert_raise(
      Mockery.Error,
      ~r"Mockery.Macro.mockable/2 needs to be invoked directly in other function.",
      fn -> Macro.Tested4.invalid() end
    )
  end
end
