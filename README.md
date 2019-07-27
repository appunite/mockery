# Mockery

[![Build Status](https://travis-ci.org/appunite/mockery.svg?branch=master)](https://travis-ci.org/appunite/mockery)
[![Codecov.io](https://codecov.io/gh/appunite/mockery/branch/master/graph/badge.svg)](https://codecov.io/gh/appunite/mockery)
[![SourceLevel](https://app.sourcelevel.io/github/appunite/mockery.svg)](https://app.sourcelevel.io/github/appunite/mockery)
[![Hex.pm](https://img.shields.io/hexpm/v/mockery.svg)](https://hex.pm/packages/mockery)
[![Hex.pm](https://img.shields.io/hexpm/dt/mockery.svg)](https://hex.pm/packages/mockery)
[![Hex.pm](https://img.shields.io/hexpm/dw/mockery.svg)](https://hex.pm/packages/mockery)

Simple mocking library for asynchronous testing in Elixir.

> Readme and documentation for last stable version are available on [hex](https://hexdocs.pm/mockery/readme.html)

## Advantages

* Mockery does not override your modules
* Mockery does not replace modules by aliasing
* Mockery does not require to pass modules as function parameter
* Mockery does not require to create callbacks or wrappers around libraries
* Mockery does not create modules during runtime (neither by `defmodule/2` nor `Module.create/3`)
* Mockery does not allow to mock non-existent function
* Mockery does not share any data between test processes

## Disadvantages

* Mockery is not designed for libraries as it would force end user to download Mockery as dependency of dependency
* Mockery can cause issues with dialyzer if you are using dialyzer with `MIX_ENV=test`

## Upgrading Erlang/OTP to 21

Erlang/OTP 21 contains some changes that prevent the package from functioning as before.</br>
Please check [migration guide](MIGRATION_TO_OTP21.md).

## Getting started

### Installation

```elixir
def deps do
  [
    {:mockery, "~> 2.3.0", runtime: false}
  ]
end
```

### Preparation of the module for mocking

```elixir
# lib/my_app/foo.ex
defmodule MyApp.Foo do
  import Mockery.Macro
  alias MyApp.Bar

  def baz, do: mockable(Bar).function()
end
```

## Basic usage

### Static value mock

```elixir
defmodule MyApp.Controller do
  # ...
  import Mockery.Macro

  def all do
    mockable(MyApp.UserService).users()
  end

  def filtered do
    mockable(MyApp.UserService).users("filter")
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

### Dynamic mock

Instead of using a static value, you can use a function with the same arity as original one.

```elixir
defmodule Foo do
  def bar(value), do: value
end

# prepare tested module
defmodule Other do
  import Mockery.Macro

  def parse(value) do
    mockable(Foo).bar(value)
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
  import Mockery.Macro

  def call(value, opts) do
    mockable(Foo).bar(value)
  end
end

# tests
defmodule TestedTest do
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

  test "assert Foo.bar/1 was called with given arg (using variable)" do
    params = %{a: 1, b: 2}

    Tested.call(params)
    assert_called Foo, :bar, [^params]
    # we need to use pinning here since assert_called/3 is a macro
    # and not a regular function call and it gets expanded accordingly
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

### Refute

Every assert_called/x function/macro has its refute_called/x counterpart.</br>
For more information see [docs](https://hexdocs.pm/mockery/Mockery.Assertions.html)

### History

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
  import Mockery.Macro

  def bar, do: mockable(Foo, by: FooGlobalMock).bar()
  def baz, do: mockable(Foo, by: FooGlobalMock).baz()
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

### Restrictions

Global mock module doesn't have to contain every function exported by the original
module, but it cannot contain a function which is not exported by the original
module.</br>
It means that:

* when you remove a function from the original module, you have to remove it from
  global mock module or Mockery will raise exception
* when you change a function name in the original module, you have to change it in
  global mock module or Mockery will raise exception
* when you change a function arity in the original module, you have to change it in
  global mock module or Mockery will raise exception

## Advanced examples

For advanced usage examples see [EXAMPLES.md](EXAMPLES.md)

## External resources

* <https://stephenbussey.com/2018/02/15/my-favorite-elixir-testing-tool-mockery>

## License

Copyright 2017-2019 Tobiasz Małecki <tobiasz.malecki@appunite.com>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

<http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
