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
        Utils.push_call(A, :fun, 0, [])

        Assertions.assert_called A, fun: 2
      end
    end

    load_cases()
    output = capture_io(fn -> ExUnit.run end)

    assert output =~ "2 tests, 2 failures"
    assert output =~ "A.fun/0 was not called"
    assert output =~ "A.fun/2 was not called"
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
        Utils.push_call(A, :fun, 2, ["a", "b"])

        Assertions.refute_called A, :fun
      end

      test "function was called multiple times" do
        Utils.push_call(A, :fun, 0, [])
        Utils.push_call(A, :fun, 2, ["a", "b"])

        Assertions.refute_called A, :fun
      end
    end

    load_cases()
    output = capture_io(fn -> ExUnit.run end)

    assert output =~ "3 tests, 3 failures"
    assert output =~ "A.fun was called at least once"
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
        Utils.push_call(A, :fun, 2, ["a", "b"])

        Assertions.refute_called A, fun: 2
      end

      test "function was called multiple times" do
        Utils.push_call(A, :fun, 0, [])
        Utils.push_call(A, :fun, 0, [])

        Assertions.refute_called A, fun: 0
      end

      test "function was called multiple times with different arities" do
        Utils.push_call(A, :fun, 0, [])
        Utils.push_call(A, :fun, 2, ["a", "b"])

        Assertions.refute_called A, fun: 0
      end
    end

    load_cases()
    output = capture_io(fn -> ExUnit.run end)

    assert output =~ "4 tests, 4 failure"
    assert output =~ "A.fun/0 was called at least once"
    assert output =~ "A.fun/2 was called at least once"
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
        Utils.push_call(A, :fun, 2, ["a", "b"])

        Assertions.assert_called A, :fun, ["a", "c"]
      end
    end

    load_cases()
    output = capture_io(fn -> ExUnit.run end)

    assert output =~ "2 tests, 2 failures"
    assert output =~ "A.fun was not called with given arguments"
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
        Utils.push_call(A, :fun, 0, [])
        Utils.push_call(A, :fun, 2, ["a", "b"])

        Assertions.refute_called A, :fun, ["a", "b"]
      end

      test "positive arity, pattern with unbound var" do
        Utils.push_call(A, :fun, 0, [])
        Utils.push_call(A, :fun, 2, ["a", "b"])

        Assertions.refute_called A, :fun, ["a", _]
      end
    end

    load_cases()
    output = capture_io(fn -> ExUnit.run end)

    assert output =~ "3 tests, 3 failures"
    assert output =~ "A.fun was called with given arguments at least once"

  end
end
