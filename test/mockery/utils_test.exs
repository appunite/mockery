defmodule Mockery.UtilsTest do
  use ExUnit.Case, async: false
  use Mockery

  alias Mockery.Utils

  test "print_mod/1 for elixir module" do
    assert Utils.print_mod(Elixir.Test) == "Test"
  end

  test "print_mod/2 for erlang module" do
    assert Utils.print_mod(:crypto) == ":crypto"
  end

  test "history_enabled?/0 returns false by default" do
    refute Utils.history_enabled?()
  end

  test "history_enabled?/0 changed by global config" do
    Application.put_env(:mockery, :history, true)
    on_exit(fn -> Application.delete_env(:mockery, :history) end)

    assert Utils.history_enabled?()
  end

  test "history_enabled?/0 global config ignored when process config present" do
    Application.put_env(:mockery, :history, true)
    on_exit(fn -> Application.delete_env(:mockery, :history) end)

    disable_history()

    refute Utils.history_enabled?()
  end
end
