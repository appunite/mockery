# Examples

## Task.Supervisor

```elixir
  defmodule MyApp.Service do
    def something, do: "value"
  end
```

```elixir
  defmodule FakeTaskSupervisor do
    use Mockery.Heritage,
      module: Task.Supervisor

    mock [start_child: 2] do
      fn(_, fun) -> fun.() end
    end
  end
```

```elixir
  defmodule MyApp.Controller do
    @task_supervisor Mockery.of(Task.Supervisor, by: FakeTaskSupervisor)
    @service Mockery.of(MyApp.Service)

    def action do
      @task_supervisor.start_child(MyApp.TaskSupervisor, fn->
        @service.something()
      end)
    end
  end
```
