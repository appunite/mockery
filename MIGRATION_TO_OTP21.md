# Migration to Erlang/OTP21

## Tuple calls

Due to this PR <https://github.com/erlang/otp/pull/1499>, it is now necessary to add
`@compile :tuple_calls` in every module where old Mockery API was used.

So, for example, most efficient way to make this

```elixir
defmodule MyProject do
  @foo Mockery.of("Foo")

  def bar, do: @foo.bar()
  def baz, do: @foo.baz()
end
```

works as expected after OTP upgrade is

```elixir
defmodule TupleCalls do
  defmacro __using__(_opts) do
    if function_exported?(Mix, :env, 0) && Mix.env() == :test do
      quote do: @compile(:tuple_calls)
    end
  end
end

defmodule MyProject do
  use TupleCalls

  @foo Mockery.of("Foo")

  def bar, do: @foo.bar()
  def baz, do: @foo.baz()
end
```

This reenables tuple calls only for `:test` environment.

## Macro-based alternative

For those who prefer not to reenable tuple calls, there is a new macro-based API.

Previous example rewritten to use macros:

```elixir
defmodule MyProject do
  use Mockery.Macro

  def bar, do: mockable(Foo).bar()
  def baz, do: mockable(Foo).baz()
end
```
