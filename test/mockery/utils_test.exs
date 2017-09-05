defmodule Mockery.UtilsTest do
  use ExUnit.Case, async: true
  alias Mockery.Utils

  test "print_mod/1 for elixir module" do
    assert Utils.print_mod(Elixir.Test) == "Test"
  end

  test "print_mod/2 for erlang module" do
    assert Utils.print_mod(:crypto) == ":crypto"
  end
end
