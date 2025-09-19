defmodule Mockery.HistoryTest do
  use ExUnit.Case
  use Mockery

  import IO.ANSI
  import Mockery.Assertions

  test "failure with too few args is marked in red" do
    enable_history()
    Mockery.Utils.push_call(A, :fun, 1, ["a"])

    tested = fn -> assert_called! A, :fun, args: ["a", "b"] end
    %{message: message} = assert_raise(ExUnit.AssertionError, tested)

    assert message =~ ~s(#{red()}["a"]#{white()})
  end

  test "failure with too many args is marked in red" do
    enable_history()
    Mockery.Utils.push_call(A, :fun, 3, ["a", "b", "c"])

    tested = fn -> assert_called! A, :fun, args: ["a", "b"] end
    %{message: message} = assert_raise(ExUnit.AssertionError, tested)

    assert message =~ ~s(#{red()}["a", "b", "c"]#{white()})
  end

  test "failure with correct number of args marks matched args in green and unmatched in red" do
    enable_history()
    Mockery.Utils.push_call(A, :fun, 2, ["a", "c"])

    tested = fn -> assert_called! A, :fun, args: ["a", "b"] end
    %{message: message} = assert_raise(ExUnit.AssertionError, tested)

    assert message =~ ~s(#{white()}[#{green()}"a"#{white()}, #{red()}"c"#{white()}])
  end

  test "failure with correct number of args marks unbound args in green as they always match" do
    enable_history()
    Mockery.Utils.push_call(A, :fun, 2, ["a", "c"])

    tested = fn -> assert_called! A, :fun, args: [_, "b"] end
    %{message: message} = assert_raise(ExUnit.AssertionError, tested)

    assert message =~ ~s(#{white()}[#{green()}"a"#{white()}, #{red()}"c"#{white()}])
  end

  test "failure with correct number of args marks pinned args according to their correctness" do
    enable_history()
    Mockery.Utils.push_call(A, :fun, 2, ["a", "c"])

    arg1 = "a"
    arg2 = "b"
    tested = fn -> assert_called! A, :fun, args: [^arg1, ^arg2] end
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
end
