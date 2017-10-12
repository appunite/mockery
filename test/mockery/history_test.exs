# credo:disable-for-this-file Credo.Check.Design.AliasUsage
defmodule Mockery.HistoryTest do
  use ExUnit.Case
  use Mockery

  import ExUnit.CaptureIO
  import IO.ANSI

  defp load_cases do
    if {:cases_loaded, 0} in ExUnit.Server.__info__(:functions) do
      ExUnit.Server.cases_loaded()
    end
  end

  test "failure with too few args" do
    defmodule Mod1 do
      use ExUnit.Case
      use Mockery

      test "failure" do
        Mockery.Utils.push_call(A, :fun, 1, ["a"])

        enable_history()
        Mockery.Assertions.assert_called A, :fun, ["a", "b"]
      end
    end

    load_cases()
    output = capture_io(fn -> ExUnit.run end)

    assert output =~ "1 test, 1 failure"
    assert output =~ ~s(#{red()}["a"]#{white()})
  end

  test "failure with too many args" do
    defmodule Mod2 do
      use ExUnit.Case
      use Mockery

      test "failure" do
        Mockery.Utils.push_call(A, :fun, 3, ["a", "b", "c"])

        enable_history()
        Mockery.Assertions.assert_called A, :fun, ["a", "b"]
      end
    end

    load_cases()
    output = capture_io(fn -> ExUnit.run end)

    assert output =~ "1 test, 1 failure"
    assert output =~ ~s(#{red()}["a", "b", "c"]#{white()})
  end

  test "failure inside pattern" do
    defmodule Mod3 do
      use ExUnit.Case
      use Mockery

      test "failure" do
        Mockery.Utils.push_call(A, :fun, 2, ["a", "c"])

        enable_history()
        Mockery.Assertions.assert_called A, :fun, ["a", "b"]
      end
    end

    load_cases()
    output = capture_io(fn -> ExUnit.run end)

    assert output =~ "1 test, 1 failure"
    assert output =~ ~s(#{white()}[#{green()}"a"#{white()}, #{red()}"c"#{white()}])
  end

  test "failure inside pattern with unbound var" do
    defmodule Mod4 do
      use ExUnit.Case
      use Mockery

      test "failure" do
        Mockery.Utils.push_call(A, :fun, 2, ["a", "c"])

        enable_history()
        Mockery.Assertions.assert_called A, :fun, [_, "b"]
      end
    end

    load_cases()
    output = capture_io(fn -> ExUnit.run end)

    assert output =~ "1 test, 1 failure"
    assert output =~ ~s(#{white()}[#{green()}"a"#{white()}, #{red()}"c"#{white()}])
  end

  test "failure inside pattern with pin" do
    defmodule Mod5 do
      use ExUnit.Case
      use Mockery

      test "failure" do
        Mockery.Utils.push_call(A, :fun, 2, ["a", "c"])

        enable_history()
        x = "b"
        Mockery.Assertions.assert_called A, :fun, ["a", ^x]
      end
    end

    load_cases()
    output = capture_io(fn -> ExUnit.run end)

    assert output =~ "1 test, 1 failure"
    assert output =~ ~s(#{white()}[#{green()}"a"#{white()}, #{red()}"c"#{white()}])
  end
end
