defmodule Mockery.History do
  @moduledoc """
  Provides calls history for Mockery.Assertions macros.

  It's disabled by default.
  It can be enabled/disabled globally by following config

      config Mockery, history: true

  Or for single test process

      Mockery.History.enable_history(true)

  Process config has higher priority than global config
  """
  alias Mockery.Utils

  @doc """
  Enables/disables history in scope of single test process

      use Mockery

      test "example" do
        #...

        enable_history()
        assert_called Foo, :bar, [_, :a]

        enable_history(false)
        assert_called Foo, :bar, [_, :b]
      end

  """
  @spec enable_history(enabled :: boolean) :: :ok
  def enable_history(enabled \\ true) do
    Process.put(__MODULE__, enabled)

    :ok
  end

  @doc false
  def print(_mod, _fun, args) when not is_list(args), do: nil
  def print(mod, fun, args) do
    quote do
      if Mockery.Utils.history_enabled? do
        """
        \n
        #{IO.ANSI.yellow()}Given:#{IO.ANSI.white()}
        #{unquote(Macro.to_string args)}

        #{IO.ANSI.yellow()}History:#{IO.ANSI.white()}
        #{unquote(colorize(mod, fun, args))}
        """
      end
    end
  end

  defp colorize(mod, fun, args) do
    arity = Enum.count(args)
    args = args |> Macro.postwalk(fn
      ({name, _, args}) when is_atom(name) and not is_list(args) -> Mockery.History.Var
      (other)-> other
    end)

    quote do
      Utils.get_calls(unquote(mod), unquote(fun))
      |> Enum.reverse()
      |> Enum.map(fn({call_arity, call_args})->
        if unquote(arity) == call_arity do
          "#{IO.ANSI.white()}[#{Mockery.History.colorize_args(unquote(args), call_args)}#{IO.ANSI.white()}]"
        else
          "#{IO.ANSI.red()}#{inspect call_args}#{IO.ANSI.white()}"
        end
      end)
      |> Enum.join("\n")
    end
  end

  @doc false
  def colorize_args(args, args2) do
    [args, args2]
    |> List.zip
    |> Enum.map(fn({given, called})->
      cond do
        given == Mockery.History.Var ->
          "#{IO.ANSI.green()}#{inspect called}#{IO.ANSI.white()}"
        given == called ->
          "#{IO.ANSI.green()}#{inspect called}#{IO.ANSI.white()}"
        :else ->
          "#{IO.ANSI.red()}#{inspect called}#{IO.ANSI.white()}"
      end
    end)
    |> Enum.join(", ")
  end
end
