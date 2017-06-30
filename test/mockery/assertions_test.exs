defmodule Mockery.AssertionsTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  describe "assert_called/2 (fun name)" do
    test "success" do
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

      ExUnit.Server.cases_loaded()
      output = capture_io(fn -> ExUnit.run end)

      assert output =~ "3 tests, 0 failures"
    end

    test "failure" do
      defmodule FunFailure do
        use ExUnit.Case

        test "when function was not called" do
          Mockery.Assertions.assert_called A, :fun
        end
      end

      ExUnit.Server.cases_loaded()
      output = capture_io(fn -> ExUnit.run end)

      assert output =~ "1 test, 1 failure"
      assert output =~ "A.fun was not called"
    end
  end

  describe "assert_called/2 (fun and arity)" do
    test "success" do
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

      ExUnit.Server.cases_loaded()
      output = capture_io(fn -> ExUnit.run end)

      assert output =~ "4 tests, 0 failure"
    end
  end

  test "failure" do
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

    ExUnit.Server.cases_loaded()
    output = capture_io(fn -> ExUnit.run end)

    assert output =~ "2 tests, 2 failures"
    assert output =~ "A.fun/0 was not called"
    assert output =~ "A.fun/2 was not called"
  end
end
