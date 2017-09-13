defmodule Mockery.UtilsTest do
  use ExUnit.Case, async: true
  use Mockery

  alias Mockery.Utils

  test "print_mod/1 for elixir module" do
    assert Utils.print_mod(Elixir.Test) == "Test"
  end

  test "print_mod/2 for erlang module" do
    assert Utils.print_mod(:crypto) == ":crypto"
  end

  test "history_enabled?/0 returns false by default" do
    refute Utils.history_enabled?
  end

  test "history_enabled?/0 changed by global config" do
    mock Application, :get_env, true

    assert Utils.history_enabled?
    assert_called Application, :get_env, [Mockery, :history, _], 1
  end

  test "history_enabled?/0 global config ignored when process config present" do
    mock Application, :get_env, true
    enable_history(false)

    refute Utils.history_enabled?
    assert_called Application, :get_env, [Mockery, :history, _], 1
  end
end
