defmodule Mockery.AssertionsTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  test "refute_called/2 (fun name) success" do
    defmodule FunRefuteSuccess do
      use ExUnit.Case

      alias Mockery.Assertions

      test "when function was not called" do
        Assertions.refute_called(A, :fun)
      end
    end

    output = capture_io(fn -> ExUnit.run() end)

    assert output =~ "1 test, 0 failures"
  end

  test "refute_called/2 (fun name) failure" do
    defmodule FunRefuteFailure do
      use ExUnit.Case

      alias Mockery.Assertions
      alias Mockery.Utils

      test "function was called once (zero arity)" do
        Utils.push_call(A, :fun, 0, [])

        Assertions.refute_called(A, :fun)
      end

      test "function was called once (positive arity)" do
        Utils.push_call(B, :fun, 2, ["a", "b"])

        Assertions.refute_called(B, :fun)
      end

      test "function was called multiple times" do
        Utils.push_call(C, :fun, 0, [])
        Utils.push_call(C, :fun, 2, ["a", "b"])

        Assertions.refute_called(C, :fun)
      end
    end

    output = capture_io(fn -> ExUnit.run() end)

    assert output =~ "3 tests, 3 failures"
    assert output =~ ~r/[^\.]A.fun was called at least once/
    assert output =~ ~r/[^\.]B.fun was called at least once/
    assert output =~ ~r/[^\.]C.fun was called at least once/
  end

  test "refute_called/2 (fun and arity) success" do
    defmodule FunArityRefuteSuccess do
      use ExUnit.Case

      alias Mockery.Assertions
      alias Mockery.Utils

      test "when function was not called" do
        Assertions.refute_called(A, fun: 0)
      end

      test "when function was called but with different_arity" do
        Utils.push_call(A, :fun, 0, [])

        Assertions.refute_called(A, fun: 2)
      end
    end

    output = capture_io(fn -> ExUnit.run() end)

    assert output =~ "2 tests, 0 failures"
  end

  test "refute_called/2 (fun and arity) failure" do
    defmodule FunArityRefuteFailute do
      use ExUnit.Case

      alias Mockery.Assertions
      alias Mockery.Utils

      test "function was called once (zero arity)" do
        Utils.push_call(A, :fun, 0, [])

        Assertions.refute_called(A, fun: 0)
      end

      test "function was called once (positive arity)" do
        Utils.push_call(B, :fun, 2, ["a", "b"])

        Assertions.refute_called(B, fun: 2)
      end

      test "function was called multiple times" do
        Utils.push_call(C, :fun, 0, [])
        Utils.push_call(C, :fun, 0, [])

        Assertions.refute_called(C, fun: 0)
      end

      test "function was called multiple times with different arities" do
        Utils.push_call(D, :fun, 0, [])
        Utils.push_call(D, :fun, 2, ["a", "b"])

        Assertions.refute_called(D, fun: 0)
      end
    end

    output = capture_io(fn -> ExUnit.run() end)

    assert output =~ "4 tests, 4 failures"
    assert output =~ ~r/[^\.]A.fun\/0 was called at least once/
    assert output =~ ~r/[^\.]B.fun\/2 was called at least once/
    assert output =~ ~r/[^\.]C.fun\/0 was called at least once/
    assert output =~ ~r/[^\.]D.fun\/0 was called at least once/
  end

  test "refute_called/3 success" do
    defmodule ArgsPatternRefuteSuccess do
      use ExUnit.Case
      require Mockery.Assertions

      alias Mockery.Assertions
      alias Mockery.Utils

      test "when function was not called" do
        Assertions.refute_called(A, :fun, ["a", "c"])
      end

      test "when function was not called with given args pattern" do
        Utils.push_call(A, :fun, 2, ["a", "b"])

        Assertions.refute_called(A, :fun, ["a", "c"])
      end
    end

    output = capture_io(fn -> ExUnit.run() end)

    assert output =~ "2 tests, 0 failures"
  end

  test "refute_called/3 failure" do
    defmodule ArgsPatternRefuteFailure do
      use ExUnit.Case
      require Mockery.Assertions

      alias Mockery.Assertions
      alias Mockery.Utils

      test "zero arity" do
        Utils.push_call(A, :fun, 0, [])
        Utils.push_call(A, :fun, 2, ["a", "b"])

        Assertions.refute_called(A, :fun, [])
      end

      test "positive arity" do
        Utils.push_call(B, :fun, 0, [])
        Utils.push_call(B, :fun, 2, ["a", "b"])

        Assertions.refute_called(B, :fun, ["a", "b"])
      end

      test "positive arity, pattern with unbound var" do
        Utils.push_call(C, :fun, 0, [])
        Utils.push_call(C, :fun, 2, ["a", "b"])

        Assertions.refute_called(C, :fun, ["a", _])
      end

      test "when args are not list" do
        Assertions.refute_called(D, :fun, "invalid")
      end
    end

    output = capture_io(fn -> ExUnit.run() end)

    assert output =~ "4 tests, 4 failures"
    assert output =~ ~r/[^\.]A.fun was called with given arguments at least once/
    assert output =~ ~r/[^\.]B.fun was called with given arguments at least once/
    assert output =~ ~r/[^\.]C.fun was called with given arguments at least once/
    assert output =~ "args for D.fun should be a list"
  end

  test "refute_called/4 success" do
    defmodule TimesArgsPatternRefuteSuccess do
      use ExUnit.Case
      require Mockery.Assertions

      alias Mockery.Assertions
      alias Mockery.Utils

      test "when function was not called" do
        Assertions.refute_called(A, :fun, ["a", "c"], 1)
      end

      test "when function was not called with given args pattern" do
        Utils.push_call(B, :fun, 2, ["a", "b"])

        Assertions.refute_called(B, :fun, ["a", "c"], 1)
      end

      test "calls count not equal to times int" do
        Utils.push_call(C, :fun, 2, ["a", "b"])
        Utils.push_call(C, :fun, 2, ["a", "b"])

        Assertions.refute_called(C, :fun, ["a", "c"], 1)
      end

      test "calls count not in times array" do
        Utils.push_call(D, :fun, 2, ["a", "b"])
        Utils.push_call(D, :fun, 2, ["a", "b"])

        Assertions.refute_called(D, :fun, ["a", "c"], [1, 3])
      end

      test "calls count not in times range" do
        Utils.push_call(E, :fun, 2, ["a", "b"])
        Utils.push_call(E, :fun, 2, ["a", "b"])

        Assertions.refute_called(E, :fun, ["a", "c"], 3..5)
      end
    end

    output = capture_io(fn -> ExUnit.run() end)

    assert output =~ "5 tests, 0 failures"
  end

  test "refute_called/4 failure" do
    defmodule TimesArgsPatternRefuteFailure do
      use ExUnit.Case
      require Mockery.Assertions

      alias Mockery.Assertions
      alias Mockery.Utils

      test "integer times" do
        Utils.push_call(A, :fun, 2, ["a", "b"])
        Utils.push_call(A, :fun, 2, ["a", "c"])
        Utils.push_call(A, :fun, 2, ["a", "d"])
        Utils.push_call(A, :fun, 2, ["x", "z"])

        Assertions.refute_called(A, :fun, ["a", _], 3)
      end

      test "array times" do
        Utils.push_call(B, :fun, 2, ["a", "b"])
        Utils.push_call(B, :fun, 2, ["a", "c"])
        Utils.push_call(B, :fun, 2, ["a", "d"])
        Utils.push_call(B, :fun, 2, ["x", "z"])

        Assertions.refute_called(B, :fun, ["a", _], [1, 3, 5])
      end

      test "range times" do
        Utils.push_call(C, :fun, 2, ["a", "b"])
        Utils.push_call(C, :fun, 2, ["a", "c"])
        Utils.push_call(C, :fun, 2, ["a", "d"])
        Utils.push_call(C, :fun, 2, ["x", "z"])

        Assertions.refute_called(C, :fun, ["a", _], 1..3)
      end

      test "when args are not list" do
        Assertions.refute_called(D, :fun, "invalid", 5)
      end
    end

    output = capture_io(fn -> ExUnit.run() end)

    assert output =~ "4 tests, 4 failures"
    assert output =~ ~r/[^\.]A.fun was called with given arguments unexpected number of times/
    assert output =~ ~r/[^\.]B.fun was called with given arguments unexpected number of times/
    assert output =~ ~r/[^\.]C.fun was called with given arguments unexpected number of times/
    assert output =~ "args for D.fun should be a list"
  end

  import Mockery.Assertions
  alias Mockery.Utils

  if Version.match?(System.version(), "~> 1.16") do
    defp wrap_msg(msg), do: "\n\n#{msg}\n\n"
  else
    defp wrap_msg(msg), do: "\n\n#{msg}\n     \n"
  end

  describe "assert_called!/3 without opts" do
    test "succeeds when function was called once (zero arity)" do
      Utils.push_call(A, :fun, 0, [])

      assert_called! A, :fun
    end

    test "succeeds when function was called once (positive arity)" do
      Utils.push_call(A, :fun, 2, ["a", "b"])

      assert_called! A, :fun
    end

    test "succeeds when function was called multiple times" do
      Utils.push_call(A, :fun, 0, [])
      Utils.push_call(A, :fun, 2, ["a", "b"])

      assert_called! A, :fun
    end

    test "fails when function was not called" do
      assert_raise ExUnit.AssertionError, wrap_msg("A.fun/x was not called"), fn ->
        assert_called! A, :fun
      end
    end
  end

  describe "assert_called!/3 with :arity in opts" do
    test "succeeds when function was called once (zero arity)" do
      Utils.push_call(A, :fun, 0, [])

      assert_called! A, :fun, arity: 0
    end

    test "succeeds when function was called once (positive arity)" do
      Utils.push_call(A, :fun, 2, ["a", "b"])

      assert_called! A, :fun, arity: 2
    end

    test "succeeds when function was called multiple times" do
      Utils.push_call(A, :fun, 1, ["a"])
      Utils.push_call(A, :fun, 1, ["a"])

      assert_called! A, :fun, arity: 1
    end

    test "succeeds when function was called multiple times with different arities" do
      Utils.push_call(A, :fun, 0, [])
      Utils.push_call(A, :fun, 2, ["a", "b"])

      assert_called! A, :fun, arity: 0
    end

    test "fails when function was not called" do
      assert_raise ExUnit.AssertionError, wrap_msg("A.fun/0 was not called"), fn ->
        assert_called! A, :fun, arity: 0
      end
    end

    test "fails when function was called but with different_arity" do
      Utils.push_call(A, :fun, 0, [])

      assert_raise ExUnit.AssertionError, wrap_msg("A.fun/2 was not called"), fn ->
        assert_called! A, :fun, arity: 2
      end
    end

    test "raises error when arity is not non_neg_integer" do
      assert_raise Mockery.Error, ":arity should be a non_neg_integer, provided: -2", fn ->
        assert_called! A, :fun, arity: -2
      end

      assert_raise Mockery.Error, ":arity should be a non_neg_integer, provided: \"wrong\"", fn ->
        assert_called! A, :fun, arity: "wrong"
      end
    end
  end

  describe "assert_called!/3 with :args in opts" do
    test "succeeds when function was called once (zero arity)" do
      Utils.push_call(A, :fun, 0, [])
      Utils.push_call(A, :fun, 2, ["a", "b"])

      assert_called! A, :fun, args: []
    end

    test "succeeds when function was called once (positive arity)" do
      Utils.push_call(A, :fun, 0, [])
      Utils.push_call(A, :fun, 2, ["a", "b"])

      assert_called! A, :fun, args: ["a", "b"]
    end

    test "succeeds on positive arity and pattern with unbound var" do
      Utils.push_call(A, :fun, 0, [])
      Utils.push_call(A, :fun, 2, ["a", "b"])

      assert_called! A, :fun, args: ["a", _]
    end

    test "succeeds on positive arity and pattern with pinned var" do
      Utils.push_call(A, :fun, 0, [])
      Utils.push_call(A, :fun, 2, ["a", "b"])

      to_pin = "b"
      assert_called! A, :fun, args: ["a", ^to_pin]
    end

    @attr "b"
    test "succeeds on positive arity and pattern with module attr" do
      Utils.push_call(A, :fun, 0, [])
      Utils.push_call(A, :fun, 2, ["a", "b"])

      assert_called! A, :fun, args: ["a", @attr]
    end

    test "succeeds on positive arity and pattern with nested module attr" do
      Utils.push_call(A, :fun, 0, [])
      Utils.push_call(A, :fun, 2, ["a", {"b", "c"}])

      assert_called! A, :fun, args: ["a", {@attr, _}]
    end

    test "fails when function was not called" do
      error_msg = wrap_msg("A.fun/2 was not called with given args")

      assert_raise ExUnit.AssertionError, error_msg, fn ->
        assert_called! A, :fun, args: ["a", "c"]
      end
    end

    test "fails when function was not called with given args pattern" do
      error_msg = wrap_msg("A.fun/2 was not called with given args")

      Utils.push_call(A, :fun, 2, ["a", "b"])

      assert_raise ExUnit.AssertionError, error_msg, fn ->
        assert_called! A, :fun, args: ["a", "c"]
      end
    end

    test "raises error when args are not list" do
      assert_raise Mockery.Error, ":args should be a list, provided: \"invalid\"", fn ->
        assert_called! A, :fun, args: "invalid"
      end
    end
  end

  describe "assert_called!/3 with :times in opts" do
    @times 2
    test "works correctly when times is non_neg_integer" do
      error_msg = wrap_msg("A.fun/x was not called expected number of times")

      # 0
      assert_raise ExUnit.AssertionError, error_msg, fn ->
        assert_called! A, :fun, times: @times
      end

      # 1
      Utils.push_call(A, :fun, 2, ["a", "b"])

      assert_raise ExUnit.AssertionError, error_msg, fn ->
        assert_called! A, :fun, times: @times
      end

      # 2
      Utils.push_call(A, :fun, 1, ["a"])

      assert_called! A, :fun, times: @times

      # 3 (> 2)
      Utils.push_call(A, :fun, 3, ["a", "b", "c"])

      assert_raise ExUnit.AssertionError, error_msg, fn ->
        assert_called! A, :fun, times: @times
      end
    end

    @times {:in, 2..3}
    test "works correctly when times is {:in, Range}" do
      error_msg = wrap_msg("A.fun/x was not called expected number of times")

      # 0
      assert_raise ExUnit.AssertionError, error_msg, fn ->
        assert_called! A, :fun, times: @times
      end

      # 1
      Utils.push_call(A, :fun, 2, ["a", "b"])

      assert_raise ExUnit.AssertionError, error_msg, fn ->
        assert_called! A, :fun, times: @times
      end

      # 2
      Utils.push_call(A, :fun, 1, ["a"])
      assert_called! A, :fun, times: @times

      # 3
      Utils.push_call(A, :fun, 3, ["a", "b", "c"])
      assert_called! A, :fun, times: @times

      # 4
      Utils.push_call(A, :fun, 2, ["a", "c"])

      assert_raise ExUnit.AssertionError, error_msg, fn ->
        assert_called! A, :fun, times: @times
      end

      # without module attribute
      Utils.push_call(B, :fun, 3, ["a", "b"])
      Utils.push_call(B, :fun, 3, ["a", "b"])

      assert_called! B, :fun, times: {:in, 1..3}
    end

    @times {:in, [2, 4]}
    test "works correctly when times is {:in, List}" do
      error_msg = wrap_msg("A.fun/x was not called expected number of times")

      # 0
      assert_raise ExUnit.AssertionError, error_msg, fn ->
        assert_called! A, :fun, times: @times
      end

      # 1
      Utils.push_call(A, :fun, 2, ["a", "b"])

      assert_raise ExUnit.AssertionError, error_msg, fn ->
        assert_called! A, :fun, times: @times
      end

      # 2
      Utils.push_call(A, :fun, 1, ["a"])
      assert_called! A, :fun, times: @times

      # 3
      Utils.push_call(A, :fun, 3, ["a", "b", "c"])

      assert_raise ExUnit.AssertionError, error_msg, fn ->
        assert_called! A, :fun, times: @times
      end

      # 4
      Utils.push_call(A, :fun, 2, ["a", "c"])
      assert_called! A, :fun, times: @times

      # 5
      Utils.push_call(A, :fun, 2, ["a", "c"])

      assert_raise ExUnit.AssertionError, error_msg, fn ->
        assert_called! A, :fun, times: @times
      end

      # without module attribute
      Utils.push_call(B, :fun, 3, ["a", "b"])
      Utils.push_call(B, :fun, 3, ["a", "b"])

      assert_called! B, :fun, times: {:in, [2, 2137]}
    end

    @times {:at_least, 2}
    test "works correctly when times is {:at_least, non_neg_integer}" do
      error_msg = wrap_msg("A.fun/x was not called expected number of times")

      # 0
      assert_raise ExUnit.AssertionError, error_msg, fn ->
        assert_called! A, :fun, times: @times
      end

      # 1
      Utils.push_call(A, :fun, 2, ["a", "b"])

      assert_raise ExUnit.AssertionError, error_msg, fn ->
        assert_called! A, :fun, times: @times
      end

      # 2
      Utils.push_call(A, :fun, 1, ["a"])
      assert_called! A, :fun, times: @times

      # 3
      Utils.push_call(A, :fun, 1, ["a"])
      assert_called! A, :fun, times: @times
    end

    @times {:at_most, 2}
    test "works correctly when times is {:at_most, non_neg_integer}" do
      error_msg = wrap_msg("A.fun/x was not called expected number of times")

      # 0
      assert_called! A, :fun, times: @times

      # 1
      Utils.push_call(A, :fun, 2, ["a", "b"])
      assert_called! A, :fun, times: @times

      # 2
      Utils.push_call(A, :fun, 1, ["a"])
      assert_called! A, :fun, times: @times

      # 3
      Utils.push_call(A, :fun, 3, ["a", "b", "c"])

      assert_raise ExUnit.AssertionError, error_msg, fn ->
        assert_called! A, :fun, times: @times
      end

      # 4
      Utils.push_call(A, :fun, 2, ["a", "c"])

      assert_raise ExUnit.AssertionError, error_msg, fn ->
        assert_called! A, :fun, times: @times
      end
    end

    test "raises error when times have invalid format" do
      assert_raise Mockery.Error, ":times have invalid format, provided: \"invalid\"", fn ->
        assert_called! A, :fun, times: "invalid"
      end
    end
  end

  describe "assert_called!/3 with multiple keys in opts" do
    test "warns when both :arity and :args opts are provided" do
      Utils.push_call(A, :fun, 2, ["a", "b"])

      {true, io} =
        with_io(:stderr, fn ->
          assert_called! A, :fun, arity: 2, args: ["a", "b"]
        end)

      assert io =~ "warning:"

      assert io =~
               ":arity and :args options are mutually exclusive in assert_called!/3, " <>
                 ":arity will be ignored"
    end

    test "works correctly when :arity and :times opts are provided" do
      error_msg = wrap_msg("A.fun/1 was not called expected number of times")

      # arity doesn't match
      Utils.push_call(A, :fun, 2, ["a", "b"])

      assert_raise ExUnit.AssertionError, error_msg, fn ->
        assert_called! A, :fun, arity: 1, times: 1
      end

      # arity and times matches
      Utils.push_call(A, :fun, 1, ["a"])
      assert_called! A, :fun, arity: 1, times: 1

      # times doesn't match
      Utils.push_call(A, :fun, 1, ["a"])

      assert_raise ExUnit.AssertionError, error_msg, fn ->
        assert_called! A, :fun, arity: 1, times: 1
      end
    end

    test "works correctly when :args and :times opts are provided" do
      error_msg = wrap_msg("A.fun/2 was not called with given args expected number of times")

      # args doesn't match
      Utils.push_call(A, :fun, 2, ["a", "b"])

      assert_raise ExUnit.AssertionError, error_msg, fn ->
        assert_called! A, :fun, args: ["a", "z"], times: 1
      end

      # args and times matches
      Utils.push_call(A, :fun, 2, ["a", "z"])
      assert_called! A, :fun, args: ["a", "z"], times: 1

      # times doesn't match
      Utils.push_call(A, :fun, 2, ["a", "z"])

      assert_raise ExUnit.AssertionError, error_msg, fn ->
        assert_called! A, :fun, args: ["a", "z"], times: 1
      end
    end
  end

  describe "assert_called!/3 with Mockery.History enabled" do
    test "displays calls history when assertion fails" do
      Mockery.History.enable_history()

      error =
        assert_raise ExUnit.AssertionError, fn ->
          assert_called! A, :fun, args: ["a", "b"]
        end

      assert error.message =~ "Given:"
      assert error.message =~ "History:"
    end

    test "displays calls history when assertion fails (no args)" do
      Mockery.History.enable_history()

      error =
        assert_raise ExUnit.AssertionError, fn ->
          assert_called! A, :fun
        end

      refute error.message =~ "Given:"
      assert error.message =~ "History:"
    end
  end
end
