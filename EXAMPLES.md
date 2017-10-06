# Examples

## Situations triggered by another process

Let's assume we have a unique resource and function that is fetching it if exist or create new otherwise.

```elixir
  @service Mockery.of("Service")

  def fetch_or_create do
    with \
      {:error, :not_found} <- @service.fetch(),
      {:ok, resource} <- @service.create()
    do
      {:ok, resource}
    else
      {:ok, resource} ->
        {:ok, resource}
      {:error, %Changeset{errors: [identifier: "has already been taken"]}} ->
        fetch_or_create()
    end
  end
```

`{:error, %Changeset{}}` in else clause can match only if between `@service.fetch` and `@service.create` there was another process that successfully created resource (`Service.create()`)

How to cover `{:error, %Changeset{}} -> fetch_or_create()` with tests?

```elixir
mock Service, :create, {:error, %Ecto.Changeset{...}}
mock Service, :fetch, fn ->
  mock Service, :fetch, &Service.fetch/0

  {:error, :not_found}
end

assert {:ok, %Resource{}} = fetch_or_create()
```

In solution above:
- `Service.create/0` is permanently mocked to return `{:error, %Changeset{}}`
- First call of `Service.fetch/0` changes mock for next calls to original function and returns `{:error, :not_found}`
- Second call of `Service.fetch/0` returns `{:ok, resource}`

## Task.Supervisor

Run tasks synchronously in test environment for easier testing

```elixir
  defmodule MyApp.Service do
    def something, do: "value"
  end
```

```elixir
  defmodule MyApp.Controller do
    @task_supervisor Mockery.of("Task.Supervisor")
    @service Mockery.of("MyApp.Service")

    def action do
      @task_supervisor.start_child(MyApp.TaskSupervisor, fn->
        @service.something()
      end)
    end
  end
```

```elixir
  defmodule MyApp.ControllerTest do
    use ExUnit.Case, async: true
    import Mockery.Assertions

    test "something is called" do
      mock Task.Supervisor, :start_child, fn(_, fun) -> fun.() end
      MyApp.Controller.action()

      assert_called MyApp.Service, :something
    end
  end
```
