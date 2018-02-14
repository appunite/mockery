[![Build Status](https://travis-ci.org/appunite/mockery.svg?branch=master)](https://travis-ci.org/appunite/mockery)
[![Codecov.io](https://codecov.io/gh/appunite/mockery/branch/master/graph/badge.svg)](https://codecov.io/gh/appunite/mockery)
[![Ebert](https://ebertapp.io/github/appunite/mockery.svg)](https://ebertapp.io/github/appunite/mockery)
[![Hex.pm](https://img.shields.io/hexpm/v/mockery.svg)](https://hex.pm/packages/mockery)
[![Hex.pm](https://img.shields.io/hexpm/dt/mockery.svg)](https://hex.pm/packages/mockery)
[![Hex.pm](https://img.shields.io/hexpm/dw/mockery.svg)](https://hex.pm/packages/mockery)

# Mockery

Simple mocking library for asynchronous testing in Elixir.

## Assumptions

* It does not override your modules
* It does not create modules during runtime
* It does not replace modules by aliasing<br>
  It contains single proxy module that checks mocks or calls original function
* It does not require to pass modules as function parameter<br>
  You won't lose any compilation warnings
* It does not require to create callbacks or wrappers around libraries
* It does not allow to mock non-existent function<br>
  It checks if original module exports function you are trying to call
* Mock created in one test doesn't interfere with other tests<br>
  Most of mock data is stored in process dictionary

## Getting started

### Mockery as compile-time dependency
Useful in large projects to avoid jumping between config files.<br>
Bad idea if you wish to release project as package.

**Installation**

```elixir
def deps do
  [
    {:mockery, "~> 2.0", runtime: false}
  ]
end
```

**Preparation of the module for mocking**

```elixir
# lib/my_app/foo.ex
defmodule MyApp.Foo do
  @bar Mockery.of(MyApp.Bar)

  def baz, do: @bar.function()
end
```

### Mockery as test dependency

**Installation**

```elixir
def deps do
  [
    {:mockery, "~> 2.0", only: :test}
  ]
end
```

**Preparation of the module for mocking**

```elixir
# lib/my_app/foo.ex
defmodule MyApp.Foo do
  @bar Application.get_env(:my_app, :bar, MyApp.Bar)

  def baz, do: @bar.function()
end

# MIX_ENV=test iex -S mix
iex(1)> Mockery.new(MyApp.Bar)
{Mockery.Proxy, MyApp.Bar, nil}

# config/test.exs
config :my_app, :bar, {Mockery.Proxy, MyApp.Bar, nil}
```

## Basic usage

#### Static value mock

```elixir
# prepare tested module
defmodule MyApp.Controller do
  # ...
  @service Mockery.of("MyApp.UserService")

  def all do
    @service.users()
  end

  def filtered do
    @service.users("filter")
  end
end

# tests
defmodule MyApp.ControllerTest do
  # ...
  import Mockery

  test "mock any function :users from MyApp.UserService" do
    mock MyApp.UserService, :users, "mock"
    assert all() == "mock"
    assert filtered() == "mock"
  end

  test "mock MyApp.UserService.users/0" do
    mock MyApp.UserService, [users: 0], "mock"
    assert all() == "mock"
    refute filtered() == "mock"
  end

  test "mock MyApp.UserService.users/0 with default value" do
    mock MyApp.UserService, users: 0
    assert all() == :mocked
    refute filtered() == :mocked
  end

  test "chaining multiple mocks for same module" do
    UserService
    |> mock([users: 0], "mock value")
    |> mock([users: 1], "mock value")
    # ...
  end
end
```
**Note**: Elixir module names are passed as a string (`"MyApp.Bar"`)
instead of atoms (`MyApp.Bar`). This reduces the compilation time
because it doesn't create a link between modules, which can cause modules to be
recompiled too often. This doesn't affect the behavior in any way.<br>
Erlang module names (e.g. `:crypto`) should be passed in as atoms.

#### Dynamic mock

Instead of using a static value, you can use a function with the same arity as original one.

```elixir
defmodule Foo do
  def bar(value), do: value
end

# prepare tested module
defmodule Other do
  @foo Mockery.of("Foo")

  def parse(value) do
    @foo.bar(value)
  end
end

# tests
defmodule OtherTest do
 # ...
 import Mockery

  test "with dynamic mock" do
    mock Foo, [bar: 1], fn(value)-> String.upcase(value) end
    assert parse("test") == "TEST"
  end
end
```

## Checking if function was called

```elixir
# prepare tested module
defmodule Tested do
  @foo Mockery.of("Foo")

  def call(value, opts) do
    @foo.bar(value)
  end
end

# tests
defmodule Tested do
  # ...
  import Mockery.Assertions
  # use Mockery # when you need to import both Mockery and Mockery.Assertions

  test "assert any function bar from module Foo was called" do
    Tested.call(1, %{})
    assert_called Foo, :bar
  end

  test "assert Foo.bar/2 was called" do
    Tested.call(1, %{})
    assert_called Foo, bar: 2
  end

  test "assert Foo.bar/2 was called with given args" do
    Tested.call(1, %{})
    assert_called Foo, :bar, [1, %{}]
  end

  test "assert Foo.bar/2 was called with 1 as first arg" do
    Tested.call(1, %{})
    assert_called Foo, :bar, [1, _]
  end

  test "assert Foo.bar/2 was called with 1 as first arg 5 times" do
    # ...
    assert_called Foo, :bar, [1, _], 5
  end

  test "assert Foo.bar/2 was called with 1 as first arg from 3 to 5 times" do
    # ...
    assert_called Foo, :bar, [1, _], 3..5
  end

  test "assert Foo.bar/2 was called with 1 as first arg 3 or 5 times" do
    # ...
    assert_called Foo, :bar, [1, _], [3, 5]
  end
end
```

#### Refute

Every assert_called/x function/macro has its refute_called/x counterpart.<br>
For more information see [docs](https://hexdocs.pm/mockery/Mockery.Assertions.html)

#### History

![history example](https://raw.githubusercontent.com/appunite/mockery/master/history.jpeg)

Mockery.History  module provides more descriptive failure messages for
assert_called/{3,4} and refute_called/{3,4} that includes a colorized list of
arguments passed to a given function in the scope of a single test process.

Disabled by default.
For more information see [docs](https://hexdocs.pm/mockery/Mockery.History.html)

## Global mock

Useful when you need to use the same mock many times across different tests

```elixir
defmodule Foo do
  def bar, do: 1
  def baz, do: 2
end

defmodule FooGlobalMock do
  def bar, do: :mocked
end

# prepare tested module
defmodule Other do
  @foo Mockery.of(Foo, by: FooGlobalMock)

  def bar, do: @foo.bar()
  def baz, do: @foo.baz()
end

# tests
defmodule OtherTest do
  # ...

  test "with global mock" do
    assert Other.bar == :mocked
    assert Other.baz == 2
  end
end
```

#### Restrictions

Global mock module doesn't have to contain every function exported by the original
module, but it cannot contain a function which is not exported by the original
module.<br>
It means that:
* when you remove a function from the original module, you have to remove it from
global mock module or Mockery will raise exception
* when you change a function name in the original module, you have to change it in
global mock module or Mockery will raise exception
* when you change a function arity in the original module, you have to change it in
global mock module or Mockery will raise exception

## Advanced examples

For advanced usage examples see [EXAMPLES.md](EXAMPLES.md)

## License

Copyright 2017-2018 Tobiasz Małecki <tobiasz.malecki@appunite.com>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
