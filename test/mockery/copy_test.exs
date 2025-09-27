defmodule Mockery.CopyTest do
  use ExUnit.Case, async: false
  import Mockery.Assertions

  describe "new/2" do
    test "returns original module when mockery isn't enabled" do
      Application.put_env(:mockery, :enable, false)
      on_exit(fn -> Application.put_env(:mockery, :enable, true) end)

      Dummy = Mockery.Copy.new(Dummy)
    end

    test "creates copy of original module" do
      copy = Mockery.Copy.new(Dummy)

      assert Enum.all?(Dummy.module_info()[:exports], &(&1 in copy.module_info()[:exports]))
    end

    test "prepares copy to be used by :mockery" do
      copy = Mockery.Copy.new(Dummy)

      assert Dummy.fun1() == 1
      refute_called! Dummy, :fun1

      assert copy.fun1() == 1
      assert_called! Dummy, :fun1
    end

    test "allows to explicitely name copy" do
      Mockery.Copy.new(Dummy, name: DummyMock)
      Application.put_env(:mockery, :dummy, DummyMock)

      assert Dummy.fun1() == 1
      refute_called! Dummy, :fun1

      copy = Application.get_env(:mockery, :dummy)
      assert copy.fun1() == 1
      assert_called! Dummy, :fun1
    end
  end

  defmodule ModuleAttributeTest do
    @dummy Mockery.Copy.new(Dummy)

    def x, do: @dummy.fun1()
  end

  test "allows to be used in module attribute" do
    refute_called! Dummy, :fun1
    assert ModuleAttributeTest.x() == 1
    assert_called! Dummy, :fun1
  end
end
