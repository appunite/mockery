# credo:disable-for-this-file Credo.Check.Design.AliasUsage
defmodule Mockery.HistoryTest do
  use ExUnit.Case
  use Mockery

  import IO.ANSI

  test "failure with too few args is marked in red" do
    enable_history()
    Mockery.Utils.push_call(A, :fun, 1, ["a"])

    tested = fn -> Mockery.Assertions.assert_called(A, :fun, ["a", "b"]) end
    %{message: message} = assert_raise(ExUnit.AssertionError, tested)

    assert message =~ ~s(#{red()}["a"]#{white()})
  end

  test "failure with too many args is marked in red" do
    enable_history()
    Mockery.Utils.push_call(A, :fun, 3, ["a", "b", "c"])

    tested = fn -> Mockery.Assertions.assert_called(A, :fun, ["a", "b"]) end
    %{message: message} = assert_raise(ExUnit.AssertionError, tested)

    assert message =~ ~s(#{red()}["a", "b", "c"]#{white()})
  end

  test "failure with correct number of args marks matched args in green and unmatched in red" do
    enable_history()
    Mockery.Utils.push_call(A, :fun, 2, ["a", "c"])

    tested = fn -> Mockery.Assertions.assert_called(A, :fun, ["a", "b"]) end
    %{message: message} = assert_raise(ExUnit.AssertionError, tested)

    assert message =~ ~s(#{white()}[#{green()}"a"#{white()}, #{red()}"c"#{white()}])
  end

  test "failure with correct number of args marks unbound args in green as they always match" do
    enable_history()
    Mockery.Utils.push_call(A, :fun, 2, ["a", "c"])

    tested = fn -> Mockery.Assertions.assert_called(A, :fun, [_, "b"]) end
    %{message: message} = assert_raise(ExUnit.AssertionError, tested)

    assert message =~ ~s(#{white()}[#{green()}"a"#{white()}, #{red()}"c"#{white()}])
  end

  test "failure with correct number of args marks pinned args according to their correctness" do
    enable_history()
    Mockery.Utils.push_call(A, :fun, 2, ["a", "c"])

    arg1 = "a"
    arg2 = "b"
    tested = fn -> Mockery.Assertions.assert_called(A, :fun, [^arg1, ^arg2]) end
    %{message: message} = assert_raise(ExUnit.AssertionError, tested)

    assert message =~ ~s(#{white()}[#{green()}"a"#{white()}, #{red()}"c"#{white()}])
  end

  test "enable_history/0" do
    Mockery.History.enable_history()

    assert Process.get(Mockery.History)
  end

  test "disable_history/0" do
    Mockery.History.disable_history()

    refute Process.get(Mockery.History)
  end

  # TODO remove in v3
  test "enable_history/1" do
    Mockery.History.enable_history(true)
    assert Process.get(Mockery.History)

    Mockery.History.enable_history(false)
    refute Process.get(Mockery.History)
  end
end
