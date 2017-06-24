[![Build Status](https://travis-ci.org/amatalai/mockery.svg?branch=master)](https://travis-ci.org/amatalai/mockery)
[![Hex.pm](https://img.shields.io/hexpm/v/mockery.svg?style=flat)](https://hex.pm/packages/mockery)

# Mockery

It's still under development.
Everything is subject to change.

## Installation

```elixir
def deps do
  [
    {:mockery, "~> 0.1.0", only: :test}
  ]
end
```

## Usage

```elixir
  defmodule MyApp.UserService do
    def users, do: []
  end
```
```elixir
  defmodule MyApp.TestUserService do
    use Mockery,
      module: MyApp.UserService
  end
```
```elixir
  defmodule MyApp.UserController do
    @service Application.get_env(:my_app, :user_service, MyApp.UserService)

    def index do
      @service.users()
    end
  end
```
```elixir
  # config/test.exs
  config :my_app,
    user_service: MyApp.TestUserService
```
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

## TODOS

- [x] basic functionality
- [x] setup CI
- [x] recompile when mocked module is changed
- [x] way to override default function outputs
- [ ] check if function was called
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
