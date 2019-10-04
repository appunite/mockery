defmodule Mockery.History do
  @moduledoc """
  Provides calls history for Mockery.Assertions macros.

  It's disabled by default.
  It can be enabled/disabled globally by following config

      config :mockery, history: true

  Or for single test process

      Mockery.History.enable_history()
      Mockery.History.disable_history()

  Process config has higher priority than global config
  """
  import IO.ANSI
  alias Mockery.Utils

  # TODO remove in v3
  @deprecated "Use enable_history/0 or disable_history/0 instead"
  @spec enable_history(enabled :: boolean) :: :ok
  def enable_history(enabled) do
    Process.put(__MODULE__, enabled)

    :ok
  end

  @doc """
  Enables history in scope of single test process

      use Mockery

      test "example" do
        #...

        enable_history()
        assert_called Foo, :bar, [_, :a]
      end

  """
  @spec enable_history :: :ok
  def enable_history do
    Process.put(__MODULE__, true)

    :ok
  end

  @doc """
  Disables history in scope of single test process

      use Mockery

      test "example" do
        #...

        disable_history()
        assert_called Foo, :bar, [_, :a]
      end

  """
  @spec disable_history :: :ok
  def disable_history do
    Process.put(__MODULE__, false)

    :ok
  end

  @doc false
  def print(_mod, _fun, args) when not is_list(args), do: nil

  def print(mod, fun, args) do
    quote do
      # credo:disable-for-lines:1 Credo.Check.Design.AliasUsage
      if Mockery.Utils.history_enabled?() do
        """
        \n
        #{yellow()}Given:#{white()}
        #{unquote(Macro.to_string(args))}

        #{yellow()}History:#{white()}
        #{unquote(colorize(mod, fun, args))}\
        """
      end
    end
  end

  defp colorize(mod, fun, args) do
    arity = Enum.count(args)
    args = postwalk_args(args)

    quote do
      Utils.get_calls(unquote(mod), unquote(fun))
      |> Enum.reverse()
      |> Enum.map(fn {call_arity, call_args} ->
        if unquote(arity) == call_arity do
          "#{white()}[" <>
            ([unquote(args), call_args]
             |> List.zip()
             |> Enum.map(fn
               {Mockery.History.UnboundVar, called} ->
                 "#{green()}#{inspect(called)}#{white()}"

               {called, called} ->
                 "#{green()}#{inspect(called)}#{white()}"

               {_given, called} ->
                 "#{red()}#{inspect(called)}#{white()}"
             end)
             |> Enum.join(", ")) <> "]"
        else
          "#{red()}#{inspect(call_args)}#{white()}"
        end
      end)
      |> Enum.join("\n")
    end
  end

  defp postwalk_args(args) do
    args
    |> Macro.postwalk(fn
      {name, _, context} = node when is_atom(name) and is_atom(context) ->
        {Mockery.History.Var, node}

      {:^, _, [{Mockery.History.Var, node}]} ->
        {Mockery.History.PinnedVar, node}

      {:@, meta, [{Mockery.History.Var, node}]} ->
        {Mockery.History.ModuleAttr, {meta, node}}

      node ->
        node
    end)
    |> Macro.postwalk(fn
      {Mockery.History.PinnedVar, node} ->
        node

      {Mockery.History.ModuleAttr, {meta, node}} ->
        Macro.escape({:@, meta, node})

      {Mockery.History.Var, _node} ->
        Mockery.History.UnboundVar

      node ->
        node
    end)
  end
end
