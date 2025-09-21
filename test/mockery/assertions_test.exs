defmodule Mockery.AssertionsTest do
  use ExUnit.Case

  import ExUnit.CaptureIO
  import Mockery.Assertions

  alias Mockery.Utils

  if Version.match?(System.version(), "~> 1.16") do
    defp wrap_msg(msg), do: "\n\n#{IO.ANSI.red()}#{msg}\n"
  else
    defp wrap_msg(msg), do: "\n\n#{IO.ANSI.red()}#{msg}     \n"
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
      assert_raise ExUnit.AssertionError, wrap_msg("A.fun/? was not called"), fn ->
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
      error_msg = wrap_msg("A.fun/? was not called expected number of times")

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
      error_msg = wrap_msg("A.fun/? was not called expected number of times")

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
      error_msg = wrap_msg("A.fun/? was not called expected number of times")

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
      error_msg = wrap_msg("A.fun/? was not called expected number of times")

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
      error_msg = wrap_msg("A.fun/? was not called expected number of times")

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

  describe "refute_called!/3 without opts" do
    test "fails when function was called once (zero arity)" do
      error_msg = wrap_msg("A.fun/? was expected not to be called, but was called")

      Utils.push_call(A, :fun, 0, [])

      assert_raise ExUnit.AssertionError, error_msg, fn ->
        refute_called! A, :fun
      end
    end

    test "fails when function was called once (positive arity)" do
      error_msg = wrap_msg("A.fun/? was expected not to be called, but was called")

      Utils.push_call(A, :fun, 2, ["a", "b"])

      assert_raise ExUnit.AssertionError, error_msg, fn ->
        refute_called! A, :fun
      end
    end

    test "fail when function was called multiple times" do
      error_msg = wrap_msg("A.fun/? was expected not to be called, but was called")

      Utils.push_call(A, :fun, 0, [])
      Utils.push_call(A, :fun, 2, ["a", "b"])

      assert_raise ExUnit.AssertionError, error_msg, fn ->
        refute_called! A, :fun
      end
    end

    test "succeeds when function was not called" do
      refute_called! A, :fun
    end
  end

  describe "refute_called!/3 with :arity in opts" do
    test "fails when function was called once (zero arity)" do
      error_msg = wrap_msg("A.fun/0 was expected not to be called, but was called")

      Utils.push_call(A, :fun, 0, [])

      assert_raise ExUnit.AssertionError, error_msg, fn ->
        refute_called! A, :fun, arity: 0
      end
    end

    test "fails when function was called once (positive arity)" do
      error_msg = wrap_msg("A.fun/2 was expected not to be called, but was called")

      Utils.push_call(A, :fun, 2, ["a", "b"])

      assert_raise ExUnit.AssertionError, error_msg, fn ->
        refute_called! A, :fun, arity: 2
      end
    end

    test "fails when function was called multiple times" do
      error_msg = wrap_msg("A.fun/1 was expected not to be called, but was called")

      Utils.push_call(A, :fun, 1, ["a"])
      Utils.push_call(A, :fun, 1, ["a"])

      assert_raise ExUnit.AssertionError, error_msg, fn ->
        refute_called! A, :fun, arity: 1
      end
    end

    test "fails when function was called multiple times with different arities" do
      error_msg = wrap_msg("A.fun/0 was expected not to be called, but was called")

      Utils.push_call(A, :fun, 0, [])
      Utils.push_call(A, :fun, 2, ["a", "b"])

      assert_raise ExUnit.AssertionError, error_msg, fn ->
        refute_called! A, :fun, arity: 0
      end
    end

    test "succeeds when function was not called" do
      refute_called! A, :fun, arity: 0
    end

    test "succeeds when function was called but with different_arity" do
      Utils.push_call(A, :fun, 0, [])

      refute_called! A, :fun, arity: 2
    end

    test "raises error when arity is not non_neg_integer" do
      assert_raise Mockery.Error, ":arity should be a non_neg_integer, provided: -2", fn ->
        refute_called! A, :fun, arity: -2
      end

      assert_raise Mockery.Error, ":arity should be a non_neg_integer, provided: \"wrong\"", fn ->
        refute_called! A, :fun, arity: "wrong"
      end
    end
  end

  describe "refute_called!/3 with :args in opts" do
    test "fails when function was called once (zero arity)" do
      error_msg =
        wrap_msg("A.fun/0 was expected not to be called with given args, but was called")

      Utils.push_call(A, :fun, 0, [])
      Utils.push_call(A, :fun, 2, ["a", "b"])

      assert_raise ExUnit.AssertionError, error_msg, fn ->
        refute_called! A, :fun, args: []
      end
    end

    test "fails when function was called once (positive arity)" do
      error_msg =
        wrap_msg("A.fun/2 was expected not to be called with given args, but was called")

      Utils.push_call(A, :fun, 0, [])
      Utils.push_call(A, :fun, 2, ["a", "b"])

      assert_raise ExUnit.AssertionError, error_msg, fn ->
        refute_called! A, :fun, args: ["a", "b"]
      end
    end

    test "fails on positive arity and pattern with unbound var" do
      error_msg =
        wrap_msg("A.fun/2 was expected not to be called with given args, but was called")

      Utils.push_call(A, :fun, 0, [])
      Utils.push_call(A, :fun, 2, ["a", "b"])

      assert_raise ExUnit.AssertionError, error_msg, fn ->
        refute_called! A, :fun, args: ["a", _]
      end
    end

    test "fails on positive arity and pattern with pinned var" do
      error_msg =
        wrap_msg("A.fun/2 was expected not to be called with given args, but was called")

      Utils.push_call(A, :fun, 0, [])
      Utils.push_call(A, :fun, 2, ["a", "b"])

      to_pin = "b"

      assert_raise ExUnit.AssertionError, error_msg, fn ->
        refute_called! A, :fun, args: ["a", ^to_pin]
      end
    end

    @attr "b"
    test "fails on positive arity and pattern with module attr" do
      error_msg =
        wrap_msg("A.fun/2 was expected not to be called with given args, but was called")

      Utils.push_call(A, :fun, 0, [])
      Utils.push_call(A, :fun, 2, ["a", "b"])

      assert_raise ExUnit.AssertionError, error_msg, fn ->
        refute_called! A, :fun, args: ["a", @attr]
      end
    end

    test "fails on positive arity and pattern with nested module attr" do
      error_msg =
        wrap_msg("A.fun/2 was expected not to be called with given args, but was called")

      Utils.push_call(A, :fun, 0, [])
      Utils.push_call(A, :fun, 2, ["a", {"b", "c"}])

      assert_raise ExUnit.AssertionError, error_msg, fn ->
        refute_called! A, :fun, args: ["a", {@attr, _}]
      end
    end

    test "succeeds when function was not called" do
      refute_called! A, :fun, args: ["a", "c"]
    end

    test "succeeds when function was not called with given args pattern" do
      Utils.push_call(A, :fun, 2, ["a", "b"])

      refute_called! A, :fun, args: ["a", "c"]
    end

    test "raises error when args are not list" do
      assert_raise Mockery.Error, ":args should be a list, provided: \"invalid\"", fn ->
        refute_called! A, :fun, args: "invalid"
      end
    end
  end

  describe "refute_called!/3 with :times in opts" do
    @times 2
    test "works correctly when times is non_neg_integer" do
      error_msg =
        wrap_msg(
          "A.fun/? was expected not to be called the given number of times" <>
            ", but was called"
        )

      # 0
      refute_called! A, :fun, times: @times

      # 1
      Utils.push_call(A, :fun, 2, ["a", "b"])

      refute_called! A, :fun, times: @times

      # 2
      Utils.push_call(A, :fun, 1, ["a"])

      assert_raise ExUnit.AssertionError, error_msg, fn ->
        refute_called! A, :fun, times: @times
      end

      # 3 (> 2)
      Utils.push_call(A, :fun, 3, ["a", "b", "c"])

      refute_called! A, :fun, times: @times
    end

    @times {:in, 2..3}
    test "works correctly when times is {:in, Range}" do
      error_msg =
        wrap_msg(
          "A.fun/? was expected not to be called the given number of times" <>
            ", but was called"
        )

      # 0
      refute_called! A, :fun, times: @times

      # 1
      Utils.push_call(A, :fun, 2, ["a", "b"])

      refute_called! A, :fun, times: @times

      # 2
      Utils.push_call(A, :fun, 1, ["a"])

      assert_raise ExUnit.AssertionError, error_msg, fn ->
        refute_called! A, :fun, times: @times
      end

      # 3
      Utils.push_call(A, :fun, 3, ["a", "b", "c"])

      assert_raise ExUnit.AssertionError, error_msg, fn ->
        refute_called! A, :fun, times: @times
      end

      # 4
      Utils.push_call(A, :fun, 2, ["a", "c"])

      refute_called! A, :fun, times: @times

      # without module attribute
      Utils.push_call(B, :fun, 3, ["a", "b"])
      Utils.push_call(B, :fun, 3, ["a", "b"])

      error_msg =
        wrap_msg(
          "B.fun/? was expected not to be called the given number of times" <>
            ", but was called"
        )

      assert_raise ExUnit.AssertionError, error_msg, fn ->
        refute_called! B, :fun, times: {:in, 1..3}
      end
    end

    @times {:in, [2, 4]}
    test "works correctly when times is {:in, List}" do
      error_msg =
        wrap_msg(
          "A.fun/? was expected not to be called the given number of times" <>
            ", but was called"
        )

      # 0
      refute_called! A, :fun, times: @times

      # 1
      Utils.push_call(A, :fun, 2, ["a", "b"])

      refute_called! A, :fun, times: @times

      # 2
      Utils.push_call(A, :fun, 1, ["a"])

      assert_raise ExUnit.AssertionError, error_msg, fn ->
        refute_called! A, :fun, times: @times
      end

      # 3
      Utils.push_call(A, :fun, 3, ["a", "b", "c"])

      refute_called! A, :fun, times: @times

      # 4
      Utils.push_call(A, :fun, 2, ["a", "c"])

      assert_raise ExUnit.AssertionError, error_msg, fn ->
        refute_called! A, :fun, times: @times
      end

      # 5
      Utils.push_call(A, :fun, 2, ["a", "c"])

      refute_called! A, :fun, times: @times

      # without module attribute
      Utils.push_call(B, :fun, 3, ["a", "b"])
      Utils.push_call(B, :fun, 3, ["a", "b"])

      error_msg =
        wrap_msg(
          "B.fun/? was expected not to be called the given number of times" <>
            ", but was called"
        )

      assert_raise ExUnit.AssertionError, error_msg, fn ->
        refute_called! B, :fun, times: {:in, [2, 2137]}
      end
    end

    @times {:at_least, 2}
    test "works correctly when times is {:at_least, non_neg_integer}" do
      error_msg =
        wrap_msg(
          "A.fun/? was expected not to be called the given number of times" <>
            ", but was called"
        )

      # 0
      refute_called! A, :fun, times: @times

      # 1
      Utils.push_call(A, :fun, 2, ["a", "b"])

      refute_called! A, :fun, times: @times

      # 2
      Utils.push_call(A, :fun, 1, ["a"])

      assert_raise ExUnit.AssertionError, error_msg, fn ->
        refute_called! A, :fun, times: @times
      end

      # 3
      Utils.push_call(A, :fun, 1, ["a"])

      assert_raise ExUnit.AssertionError, error_msg, fn ->
        refute_called! A, :fun, times: @times
      end
    end

    @times {:at_most, 2}
    test "works correctly when times is {:at_most, non_neg_integer}" do
      error_msg =
        wrap_msg(
          "A.fun/? was expected not to be called the given number of times" <>
            ", but was called"
        )

      # 0
      assert_raise ExUnit.AssertionError, error_msg, fn ->
        refute_called! A, :fun, times: @times
      end

      # 1
      Utils.push_call(A, :fun, 2, ["a", "b"])

      assert_raise ExUnit.AssertionError, error_msg, fn ->
        refute_called! A, :fun, times: @times
      end

      # 2
      Utils.push_call(A, :fun, 1, ["a"])

      assert_raise ExUnit.AssertionError, error_msg, fn ->
        refute_called! A, :fun, times: @times
      end

      # 3
      Utils.push_call(A, :fun, 3, ["a", "b", "c"])

      refute_called! A, :fun, times: @times

      # 4
      Utils.push_call(A, :fun, 2, ["a", "c"])

      refute_called! A, :fun, times: @times
    end

    test "raises error when times have invalid format" do
      assert_raise Mockery.Error, ":times have invalid format, provided: \"invalid\"", fn ->
        refute_called! A, :fun, times: "invalid"
      end
    end
  end

  describe "refute_called!/3 with multiple keys in opts" do
    test "warns when both :arity and :args opts are provided" do
      {false, io} =
        with_io(:stderr, fn ->
          refute_called! A, :fun, arity: 2, args: ["a", "b"]
        end)

      assert io =~ "warning:"

      assert io =~
               ":arity and :args options are mutually exclusive in assert_called!/3, " <>
                 ":arity will be ignored"
    end

    test "works correctly when :arity and :times opts are provided" do
      # arity doesn't match
      Utils.push_call(A, :fun, 2, ["a", "b"])

      refute_called! A, :fun, arity: 1, times: 1

      # arity and times matches
      Utils.push_call(A, :fun, 1, ["a"])

      assert_raise ExUnit.AssertionError, fn ->
        refute_called! A, :fun, arity: 1, times: 1
      end

      # times doesn't match
      Utils.push_call(A, :fun, 1, ["a"])

      refute_called! A, :fun, arity: 1, times: 1
    end

    test "works correctly when :args and :times opts are provided" do
      # args doesn't match
      Utils.push_call(A, :fun, 2, ["a", "b"])

      refute_called! A, :fun, args: ["a", "z"], times: 1

      # args and times matches
      Utils.push_call(A, :fun, 2, ["a", "z"])

      assert_raise ExUnit.AssertionError, fn ->
        refute_called! A, :fun, args: ["a", "z"], times: 1
      end

      # times doesn't match
      Utils.push_call(A, :fun, 2, ["a", "z"])

      refute_called! A, :fun, args: ["a", "z"], times: 1
    end
  end

  describe "refute_called!/3 with Mockery.History enabled" do
    test "displays calls history when assertion fails" do
      Mockery.History.enable_history()

      Utils.push_call(A, :fun, 2, ["a", "b"])

      error =
        assert_raise ExUnit.AssertionError, fn ->
          refute_called! A, :fun, args: ["a", "b"]
        end

      assert error.message =~ "Given:"
      assert error.message =~ "History:"
    end

    test "displays calls history when assertion fails (no args)" do
      Mockery.History.enable_history()

      Utils.push_call(A, :fun, 2, ["a", "b"])

      error =
        assert_raise ExUnit.AssertionError, fn ->
          refute_called! A, :fun
        end

      refute error.message =~ "Given:"
      assert error.message =~ "History:"
    end
  end
end
