[![Build Status](https://travis-ci.org/amatalai/mockery.svg?branch=master)](https://travis-ci.org/amatalai/mockery)
[![Hex.pm](https://img.shields.io/hexpm/v/mockery.svg?style=flat)](https://hex.pm/packages/mockery)

# Mockery

It's still under development.
Everything is subject to change.

## Installation

```elixir
def deps do
  [
    {:mockery, "~> 0.3.1"}
  ]
end
```

## Basic usage

```elixir
  defmodule MyApp.UserService do
    def users, do: []
  end
```

Prepare tested module:

```elixir
  defmodule MyApp.UserController do
    @service Mockery.of(MyApp.UserService)

    def index do
      @service.users()
    end
  end
```

Use mock in your tests:

```elixir
  defmodule MyApp.UserControllerTest do
    use ExUnit.Case, async: true
    import Mockery

    alias MyApp.UserController, as: Controller
    alias MyApp.UserService, as: Service

    describe "index" do
      test "not mocked" do
        assert Controller.index() == []
      end

      test "mocked" do
        mock(Service, :users, [:john, :donald])

        assert Controller.index() == [:john, :donald]
      end
    end
  end
```

## Global mock

Create helper module:

```elixir
  defmodule MyApp.TestUserService do
    use Mockery.Heritage,
      module: MyApp.UserService

    mock [users: 0] do
      [:user1, :user2, :user3]
    end
  end
```

Prepare tested module:

```elixir
  defmodule MyApp.UserController do
    @service Mockery.of(MyApp.UserService, by: MyApp.TestUserService)

    def index do
      @service.users()
    end
  end
```

## TODOS

- [x] basic functionality
- [x] setup CI
- [x] global mock (through Mockery.Heritage)
- [x] let it work without recompiling additional module after each change
- [x] let Mockery.of/2 work without :by option
- [ ] let global mock work with only function name (without arity)
- [ ] way to check if function was called
- [ ] docs

## License

Copyright 2017 Tobiasz Małecki <tobiasz.malecki@appunite.com>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
