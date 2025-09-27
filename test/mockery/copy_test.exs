defmodule Mockery.CopyTest do
  use ExUnit.Case, async: false
  import Mockery.Assertions

  describe "of/2" do
    test "returns original module when mockery isn't enabled" do
      Application.put_env(:mockery, :enable, false)
      on_exit(fn -> Application.put_env(:mockery, :enable, true) end)

      Dummy = Mockery.Copy.of(Dummy)
    end

    test "creates copy of original module" do
      copy = Mockery.Copy.of(Dummy)

      assert Enum.all?(Dummy.module_info()[:exports], &(&1 in copy.module_info()[:exports]))
    end

    test "prepares copy to be used by :mockery" do
      copy = Mockery.Copy.of(Dummy)

      assert Dummy.fun1() == 1
      refute_called! Dummy, :fun1

      assert copy.fun1() == 1
      assert_called! Dummy, :fun1
    end

    test "allows to explicitely name copy" do
      Mockery.Copy.of(Dummy, name: DummyMock)
      Application.put_env(:mockery, :dummy, DummyMock)

      assert Dummy.fun1() == 1
      refute_called! Dummy, :fun1

      copy = Application.get_env(:mockery, :dummy)
      assert copy.fun1() == 1
      assert_called! Dummy, :fun1
    end

    test "allow to be used with erlang modules" do
      copy = Mockery.Copy.of(:crypto)

      refute_called! :crypto, :strong_rand_bytes
      assert copy.strong_rand_bytes(1)
      assert_called! :crypto, :strong_rand_bytes
    end

    defmodule ModuleAttributeTest do
      @dummy Mockery.Copy.of(Dummy)

      def x, do: @dummy.fun1()
    end

    test "allows to be used in module attribute" do
      refute_called! Dummy, :fun1
      assert ModuleAttributeTest.x() == 1
      assert_called! Dummy, :fun1
    end

    defmodule DummyGlobalMock do
      def fun1, do: 2137
    end

    test "supports global mocks" do
      copy1 = Mockery.Copy.of(Dummy)
      copy2 = Mockery.Copy.of(Dummy, by: DummyGlobalMock)

      assert Dummy.fun1() == 1
      assert copy1.fun1() == 1
      assert copy2.fun1() == 2137
    end
  end
end
