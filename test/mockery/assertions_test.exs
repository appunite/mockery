defmodule Mockery.AssertionsTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  defp load_cases do
    if {:cases_loaded, 0} in ExUnit.Server.__info__(:functions) do
      ExUnit.Server.cases_loaded()
    end
  end

  test "assert_called/2 (fun name) success" do
    defmodule FunSuccess do
      use ExUnit.Case

      alias Mockery.Assertions
      alias Mockery.Utils

      test "function was called once (zero arity)" do
        Utils.push_call(A, :fun, 0, [])

        Assertions.assert_called A, :fun
      end

      test "function was called once (positive arity)" do
        Utils.push_call(A, :fun, 2, ["a", "b"])

        Assertions.assert_called A, :fun
      end

      test "function was called multiple times" do
        Utils.push_call(A, :fun, 0, [])
        Utils.push_call(A, :fun, 2, ["a", "b"])

        Assertions.assert_called A, :fun
      end
    end

    load_cases()
    output = capture_io(fn -> ExUnit.run end)

    assert output =~ "3 tests, 0 failures"
  end

  test "assert_called/2 (fun name) failure" do
    defmodule FunFailure do
      use ExUnit.Case

      test "when function was not called" do
        Mockery.Assertions.assert_called A, :fun
      end
    end

    load_cases()
    output = capture_io(fn -> ExUnit.run end)

    assert output =~ "1 test, 1 failure"
    assert output =~ "A.fun was not called"
  end

  test "assert_called/2 (fun and arity) success" do
    defmodule FunAritySuccess do
      use ExUnit.Case

      alias Mockery.Assertions
      alias Mockery.Utils

      test "function was called once (zero arity)" do
        Utils.push_call(A, :fun, 0, [])

        Assertions.assert_called A, fun: 0
      end

      test "function was called once (positive arity)" do
        Utils.push_call(A, :fun, 2, ["a", "b"])

        Assertions.assert_called A, fun: 2
      end

      test "function was called multiple times" do
        Utils.push_call(A, :fun, 0, [])
        Utils.push_call(A, :fun, 0, [])

        Assertions.assert_called A, fun: 0
      end

      test "function was called multiple times with different arities" do
        Utils.push_call(A, :fun, 0, [])
        Utils.push_call(A, :fun, 2, ["a", "b"])

        Assertions.assert_called A, fun: 0
      end
    end

    load_cases()
    output = capture_io(fn -> ExUnit.run end)

    assert output =~ "4 tests, 0 failure"
  end

  test "assert_called/2 (fun and arity) failure" do
    defmodule FunArityFailure do
      use ExUnit.Case

      alias Mockery.Assertions
      alias Mockery.Utils

      test "when function was not called" do
        Assertions.assert_called A, fun: 0
      end

      test "when function was called but with different_arity" do
        Utils.push_call(B, :fun, 0, [])

        Assertions.assert_called B, fun: 2
      end
    end

    load_cases()
    output = capture_io(fn -> ExUnit.run end)

    assert output =~ "2 tests, 2 failures"
    assert output =~ "A.fun/0 was not called"
    assert output =~ "B.fun/2 was not called"
  end

  test "refute_called/2 (fun name) success" do
    defmodule FunRefuteSuccess do
      use ExUnit.Case

      test "when function was not called" do
        Mockery.Assertions.refute_called A, :fun
      end
    end

    load_cases()
    output = capture_io(fn -> ExUnit.run end)

    assert output =~ "1 test, 0 failures"
  end

  test "refute_called/2 (fun name) failure" do
    defmodule FunRefuteFailure do
      use ExUnit.Case

      alias Mockery.Assertions
      alias Mockery.Utils

      test "function was called once (zero arity)" do
        Utils.push_call(A, :fun, 0, [])

        Assertions.refute_called A, :fun
      end

      test "function was called once (positive arity)" do
        Utils.push_call(B, :fun, 2, ["a", "b"])

        Assertions.refute_called B, :fun
      end

      test "function was called multiple times" do
        Utils.push_call(C, :fun, 0, [])
        Utils.push_call(C, :fun, 2, ["a", "b"])

        Assertions.refute_called C, :fun
      end
    end

    load_cases()
    output = capture_io(fn -> ExUnit.run end)

    assert output =~ "3 tests, 3 failures"
    assert output =~ "A.fun was called at least once"
    assert output =~ "B.fun was called at least once"
    assert output =~ "C.fun was called at least once"
  end

  test "refute_called/2 (fun and arity) success" do
    defmodule FunArityRefuteSuccess do
      use ExUnit.Case

      alias Mockery.Assertions
      alias Mockery.Utils

      test "when function was not called" do
        Assertions.refute_called A, fun: 0
      end

      test "when function was called but with different_arity" do
        Utils.push_call(A, :fun, 0, [])

        Assertions.refute_called A, fun: 2
      end
    end

    load_cases()
    output = capture_io(fn -> ExUnit.run end)

    assert output =~ "2 tests, 0 failures"
  end

  test "refute_called/2 (fun and arity) failure" do
    defmodule FunArityRefuteFailute do
      use ExUnit.Case

      alias Mockery.Assertions
      alias Mockery.Utils

      test "function was called once (zero arity)" do
        Utils.push_call(A, :fun, 0, [])

        Assertions.refute_called A, fun: 0
      end

      test "function was called once (positive arity)" do
        Utils.push_call(B, :fun, 2, ["a", "b"])

        Assertions.refute_called B, fun: 2
      end

      test "function was called multiple times" do
        Utils.push_call(C, :fun, 0, [])
        Utils.push_call(C, :fun, 0, [])

        Assertions.refute_called C, fun: 0
      end

      test "function was called multiple times with different arities" do
        Utils.push_call(D, :fun, 0, [])
        Utils.push_call(D, :fun, 2, ["a", "b"])

        Assertions.refute_called D, fun: 0
      end
    end

    load_cases()
    output = capture_io(fn -> ExUnit.run end)

    assert output =~ "4 tests, 4 failures"
    assert output =~ "A.fun/0 was called at least once"
    assert output =~ "B.fun/2 was called at least once"
    assert output =~ "C.fun/0 was called at least once"
    assert output =~ "D.fun/0 was called at least once"
  end

  test "assert_called/3 success" do
    defmodule ArgsPatternSuccess do
      use ExUnit.Case
      require Mockery.Assertions

      alias Mockery.Assertions
      alias Mockery.Utils

      test "zero arity" do
        Utils.push_call(A, :fun, 0, [])
        Utils.push_call(A, :fun, 2, ["a", "b"])

        Assertions.assert_called A, :fun, []
      end

      test "positive arity" do
        Utils.push_call(A, :fun, 0, [])
        Utils.push_call(A, :fun, 2, ["a", "b"])

        Assertions.assert_called A, :fun, ["a", "b"]
      end

      test "positive arity, pattern with unbound var" do
        Utils.push_call(A, :fun, 0, [])
        Utils.push_call(A, :fun, 2, ["a", "b"])

        Assertions.assert_called A, :fun, ["a", _]
      end
    end

    load_cases()
    output = capture_io(fn -> ExUnit.run end)

    assert output =~ "3 tests, 0 failures"
  end

  test "assert_called/3 failure" do
    defmodule ArgsPatternFailure do
      use ExUnit.Case
      require Mockery.Assertions

      alias Mockery.Assertions
      alias Mockery.Utils

      test "when function was not called" do
        Assertions.assert_called A, :fun, ["a", "c"]
      end

      test "when function was not called with given args pattern" do
        Utils.push_call(B, :fun, 2, ["a", "b"])

        Assertions.assert_called B, :fun, ["a", "c"]
      end

      test "when args are not list" do
        Assertions.assert_called C, :fun, "invalid"
      end
    end

    load_cases()
    output = capture_io(fn -> ExUnit.run end)

    assert output =~ "3 tests, 3 failures"
    assert output =~ "A.fun was not called with given arguments"
    assert output =~ "B.fun was not called with given arguments"
    assert output =~ "args for Elixir.C.fun should be a list"
  end

  test "refute_called/3 success" do
    defmodule ArgsPatternRefuteSuccess do
      use ExUnit.Case
      require Mockery.Assertions

      alias Mockery.Assertions
      alias Mockery.Utils

      test "when function was not called" do
        Assertions.refute_called A, :fun, ["a", "c"]
      end

      test "when function was not called with given args pattern" do
        Utils.push_call(A, :fun, 2, ["a", "b"])

        Assertions.refute_called A, :fun, ["a", "c"]
      end
    end

    load_cases()
    output = capture_io(fn -> ExUnit.run end)

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

        Assertions.refute_called A, :fun, []
      end

      test "positive arity" do
        Utils.push_call(B, :fun, 0, [])
        Utils.push_call(B, :fun, 2, ["a", "b"])

        Assertions.refute_called B, :fun, ["a", "b"]
      end

      test "positive arity, pattern with unbound var" do
        Utils.push_call(C, :fun, 0, [])
        Utils.push_call(C, :fun, 2, ["a", "b"])

        Assertions.refute_called C, :fun, ["a", _]
      end

      test "when args are not list" do
        Assertions.refute_called D, :fun, "invalid"
      end
    end

    load_cases()
    output = capture_io(fn -> ExUnit.run end)

    assert output =~ "4 tests, 4 failures"
    assert output =~ "A.fun was called with given arguments at least once"
    assert output =~ "B.fun was called with given arguments at least once"
    assert output =~ "C.fun was called with given arguments at least once"
    assert output =~ "args for Elixir.D.fun should be a list"
  end

  test "assert_called/4 success" do
    defmodule TimesArgsPatternSuccess do
      use ExUnit.Case
      require Mockery.Assertions

      alias Mockery.Assertions
      alias Mockery.Utils

      test "integer times" do
        Utils.push_call(A, :fun, 2, ["a", "b"])
        Utils.push_call(A, :fun, 2, ["a", "c"])
        Utils.push_call(A, :fun, 2, ["a", "d"])
        Utils.push_call(A, :fun, 2, ["x", "z"])

        Assertions.assert_called A, :fun, ["a", _], 3
      end

      test "array times" do
        Utils.push_call(A, :fun, 2, ["a", "b"])
        Utils.push_call(A, :fun, 2, ["a", "c"])
        Utils.push_call(A, :fun, 2, ["a", "d"])
        Utils.push_call(A, :fun, 2, ["x", "z"])

        Assertions.assert_called A, :fun, ["a", _], [1, 3, 5]
      end

      test "range times" do
        Utils.push_call(A, :fun, 2, ["a", "b"])
        Utils.push_call(A, :fun, 2, ["a", "c"])
        Utils.push_call(A, :fun, 2, ["a", "d"])
        Utils.push_call(A, :fun, 2, ["x", "z"])

        Assertions.assert_called A, :fun, ["a", _], 1..3
      end
    end

    load_cases()
    output = capture_io(fn -> ExUnit.run end)

    assert output =~ "3 tests, 0 failures"
  end

  test "assert_called/4 failure" do
    defmodule TimesArgsPatternFailure do
      use ExUnit.Case
      require Mockery.Assertions

      alias Mockery.Assertions
      alias Mockery.Utils

      test "when function was not called" do
        Assertions.assert_called A, :fun, ["a", "c"], 1
      end

      test "when function was not called with given args pattern" do
        Utils.push_call(B, :fun, 2, ["a", "b"])

        Assertions.assert_called B, :fun, ["a", "c"], 1
      end

      test "calls count not equal to times int" do
        Utils.push_call(C, :fun, 2, ["a", "b"])
        Utils.push_call(C, :fun, 2, ["a", "b"])

        Assertions.assert_called C, :fun, ["a", "c"], 1
      end

      test "calls count not in times array" do
        Utils.push_call(D, :fun, 2, ["a", "b"])
        Utils.push_call(D, :fun, 2, ["a", "b"])

        Assertions.assert_called D, :fun, ["a", "c"], [1, 3]
      end

      test "calls count not in times range" do
        Utils.push_call(E, :fun, 2, ["a", "b"])
        Utils.push_call(E, :fun, 2, ["a", "b"])

        Assertions.assert_called E, :fun, ["a", "c"], 3..5
      end

      test "when args are not list" do
        Assertions.assert_called F, :fun, "invalid", 5
      end
    end

    load_cases()
    output = capture_io(fn -> ExUnit.run end)

    assert output =~ "6 tests, 6 failures"
    assert output =~ "A.fun was not called with given arguments expected number of times"
    assert output =~ "B.fun was not called with given arguments expected number of times"
    assert output =~ "C.fun was not called with given arguments expected number of times"
    assert output =~ "D.fun was not called with given arguments expected number of times"
    assert output =~ "E.fun was not called with given arguments expected number of times"
    assert output =~ "args for Elixir.F.fun should be a list"
  end

  test "refute_called/4 success" do
    defmodule TimesArgsPatternRefuteSuccess do
      use ExUnit.Case
      require Mockery.Assertions

      alias Mockery.Assertions
      alias Mockery.Utils

      test "when function was not called" do
        Assertions.refute_called A, :fun, ["a", "c"], 1
      end

      test "when function was not called with given args pattern" do
        Utils.push_call(B, :fun, 2, ["a", "b"])

        Assertions.refute_called B, :fun, ["a", "c"], 1
      end

      test "calls count not equal to times int" do
        Utils.push_call(C, :fun, 2, ["a", "b"])
        Utils.push_call(C, :fun, 2, ["a", "b"])

        Assertions.refute_called C, :fun, ["a", "c"], 1
      end

      test "calls count not in times array" do
        Utils.push_call(D, :fun, 2, ["a", "b"])
        Utils.push_call(D, :fun, 2, ["a", "b"])

        Assertions.refute_called D, :fun, ["a", "c"], [1, 3]
      end

      test "calls count not in times range" do
        Utils.push_call(E, :fun, 2, ["a", "b"])
        Utils.push_call(E, :fun, 2, ["a", "b"])

        Assertions.refute_called E, :fun, ["a", "c"], 3..5
      end
    end

    load_cases()
    output = capture_io(fn -> ExUnit.run end)

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

        Assertions.refute_called A, :fun, ["a", _], 3
      end

      test "array times" do
        Utils.push_call(B, :fun, 2, ["a", "b"])
        Utils.push_call(B, :fun, 2, ["a", "c"])
        Utils.push_call(B, :fun, 2, ["a", "d"])
        Utils.push_call(B, :fun, 2, ["x", "z"])

        Assertions.refute_called B, :fun, ["a", _], [1, 3, 5]
      end

      test "range times" do
        Utils.push_call(C, :fun, 2, ["a", "b"])
        Utils.push_call(C, :fun, 2, ["a", "c"])
        Utils.push_call(C, :fun, 2, ["a", "d"])
        Utils.push_call(C, :fun, 2, ["x", "z"])

        Assertions.refute_called C, :fun, ["a", _], 1..3
      end

      test "when args are not list" do
        Assertions.refute_called D, :fun, "invalid", 5
      end
    end

    load_cases()
    output = capture_io(fn -> ExUnit.run end)

    assert output =~ "4 tests, 4 failures"
    assert output =~ "A.fun was called with given arguments unexpected number of times"
    assert output =~ "B.fun was called with given arguments unexpected number of times"
    assert output =~ "C.fun was called with given arguments unexpected number of times"
    assert output =~ "args for Elixir.D.fun should be a list"
  end
end
