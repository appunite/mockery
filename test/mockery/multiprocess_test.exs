defmodule Mockery.MultiprocessTest do
  use ExUnit.Case, async: true
  import Mockery

  defmodule A do
    def run do
      "real"
    end
  end

  defmodule B do
    import Mockery.Macro

    def run do
      mockable(A).run
    end
  end

  test "same process mocking works" do
    mock(A, [run: 0], "mock")
    assert B.run() == "mock"
  end

  test "multiprocess mocking does not work" do
    mock(A, [run: 0], "mock")

    spawn(fn ->
      assert B.run() == "real"
    end)
  end
end
