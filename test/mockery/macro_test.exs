defmodule Mockery.MacroTest do
  use ExUnit.Case, async: true
  use Mockery.Macro

  test "mockable/2 dev env (atom erlang mod)" do
    assert mockable(:a, env: :dev) == :a
    refute Process.get(Mockery.MockableModule)

    assert mockable(:a, env: :dev, by: X) == :a
    refute Process.get(Mockery.MockableModule)
  end

  test "mockable/2 test env (atom erlang mod) without global mock" do
    assert mockable(:a) == Mockery.Proxy.MacroProxy
    assert Process.get(Mockery.MockableModule) == [{:a, nil}]
  end

  test "mockable/2 test env (atom erlang mod) with global mock" do
    assert mockable(:a, by: X) == Mockery.Proxy.MacroProxy
    assert Process.get(Mockery.MockableModule) == [{:a, X}]
  end

  test "mockable/2 dev env (atom elixir mod)" do
    assert mockable(A, env: :dev) == A
    refute Process.get(Mockery.MockableModule)

    assert mockable(A, env: :dev, by: X) == A
    refute Process.get(Mockery.MockableModule)
  end

  test "mockable/2 test env (atom elixir mod) without global mock" do
    assert mockable(A) == Mockery.Proxy.MacroProxy
    assert Process.get(Mockery.MockableModule) == [{A, nil}]
  end

  test "mockable/2 test env (atom elixir mod) with global mock" do
    assert mockable(A, by: X) == Mockery.Proxy.MacroProxy
    assert Process.get(Mockery.MockableModule) == [{A, X}]
  end
end
