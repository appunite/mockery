[![Build Status](https://travis-ci.org/appunite/mockery.svg?branch=master)](https://travis-ci.org/appunite/mockery)
[![Coverage Status](https://coveralls.io/repos/github/appunite/mockery/badge.svg?branch=master)](https://coveralls.io/github/appunite/mockery?branch=master)
[![GitHub issues](https://img.shields.io/github/issues/appunite/mockery.svg)](https://github.com/appunite/mockery/issues)
[![Hex.pm](https://img.shields.io/hexpm/v/mockery.svg?style=flat)](https://hex.pm/packages/mockery)
[![Hex.pm](https://img.shields.io/hexpm/dt/mockery.svg)](https://hex.pm/packages/mockery)
[![Hex.pm](https://img.shields.io/hexpm/dw/mockery.svg)](https://hex.pm/packages/mockery)

# Mockery

Simple mocking library for asynchronous testing in Elixir.

In test environment it replaces prepared modules by mockable proxy. In other environments your modules remain unchanged.

## Installation

```elixir
def deps do
  [
    {:mockery, "~> 1.0.0"}
  ]
end
```

## Basic usage

Mock

```elixir
# prepare tested module
@service Mockery.of(MyApp.UserService)

def all do
  @service.users()
end

def filtered do
  @service.users("filter")
end

# tests
import Mockery

# mock any function :users from MyApp.UserService
mock MyApp.UserService, :users, "mock"
assert all() == "mock"
assert filtered() == "mock"

# mock MyApp.UserService.users/0
mock MyApp.UserService, [users: 0], "mock"
assert all() == "mock"
refute filtered() == "mock"
```

Dynamic mock

```elixir
defmodule Foo do
  def bar(value), do: value
end

# prepare tested module
@foo Mockery.of(Foo)

def parse(value) do
  @foo.bar(value)
end

# tests
import Mockery

mock Foo, [bar: 1], fn(value)-> String.upcase(value) end
assert parse("test") == "TEST"
```

## Check if function was called

```elixir
# prepare tested module
@foo Mockery.of(Foo)

def call(value, opts) do
  @foo.bar(value)
end

# tests
import Mockery.Assertions
# use Mockery # when need to import both Mockery and Mockery.Assertions

# assert any function bar from module Foo was called
call(1, %{})
assert_called Foo, :bar

# assert Foo.bar/2 was called
call(1, %{})
assert_called Foo, bar: 2

# assert Foo.bar/2 was called with given args
call(1, %{})
assert_called Foo, :bar, [1, %{}]

# assert Foo.bar/2 was called with 1 as first arg
call(1, %{})
assert_called Foo, :bar, [1, _]
```

## Global mock

```elixir
# create helper module
defmodule MyApp.TestUserService do
  use Mockery.Heritage,
    module: MyApp.UserService

  mock [users: 0] do
    [:user1, :user2, :user3]
  end
end

# prepare tested module
defmodule MyApp.UserController do
  @service Mockery.of(MyApp.UserService, by: MyApp.TestUserService)

  def index do
    @service.users()
  end
end

# tests
assert index() == [:user1, :user2, :user3]
```

## Advanced examples

For advanced usage examples see [EXAMPLES.md](EXAMPLES.md)

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
