defmodule Mockery.MacroTest do
  use ExUnit.Case, async: true
  use Mockery.Macro

  describe "mockable/2" do
    test "dev env (atom erlang mod)" do
      assert mockable(:a, env: :dev) == :a
      refute Process.get(Mockery.MockableModule)

      assert mockable(:a, env: :dev, by: X) == :a
      refute Process.get(Mockery.MockableModule)
    end

    test "test env (atom erlang mod) without global mock" do
      assert mockable(:a) == Mockery.Proxy.MacroProxy
      assert Process.get(Mockery.MockableModule) == [{:a, nil}]
    end

    test "test env (atom erlang mod) with global mock" do
      assert mockable(:a, by: X) == Mockery.Proxy.MacroProxy
      assert Process.get(Mockery.MockableModule) == [{:a, X}]
    end

    test "dev env (atom elixir mod)" do
      assert mockable(A, env: :dev) == A
      refute Process.get(Mockery.MockableModule)

      assert mockable(A, env: :dev, by: X) == A
      refute Process.get(Mockery.MockableModule)
    end

    test "test env (atom elixir mod) without global mock" do
      assert mockable(A) == Mockery.Proxy.MacroProxy
      assert Process.get(Mockery.MockableModule) == [{A, nil}]
    end

    test "test env (atom elixir mod) with global mock" do
      assert mockable(A, by: X) == Mockery.Proxy.MacroProxy
      assert Process.get(Mockery.MockableModule) == [{A, X}]
    end
  end

  describe "defmock/2" do
    defmodule Wrapper do
      use Mockery.Macro

      defmock :mock, A
      defmock :global, A, by: X

      def fun1, do: mock()
      def fun2, do: global()
    end

    test "defmock two-arg macro expands to mockable/1" do
      assert Wrapper.fun1() == Mockery.Proxy.MacroProxy
      assert Process.get(Mockery.MockableModule) == [{A, nil}]
    end

    test "defmock three-arg macro expands to mockable/2" do
      assert Wrapper.fun2() == Mockery.Proxy.MacroProxy
      assert Process.get(Mockery.MockableModule) == [{A, X}]
    end
  end
end
