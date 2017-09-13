# Changelog

## 1.2.0
* Introduced `Mockery.History`

## 1.1.1
* More descriptive errors (when args are not list) for:
  * `Mockery.Assertions.assert_called/3`
  * `Mockery.Assertions.refute_called/3`
  * `Mockery.Assertions.assert_called/4`
  * `Mockery.Assertions.refute_called/4`
* Removed unnecessary `Elixir.` namespace from module names in error messages

## 1.1.0
* Added `Mockery.mock/2` (`Mockery.mock/3` value defaults to `:mocked`)
* Added `Mockery.Assertions.assert_called/4` macro
* Added `Mockery.Assertions.refute_called/4` macro

## 1.0.1
* Fixed issue when mocking with `nil` or `false`

## 1.0.0
* Added `use Mockery` for importing both `Mockery` and `Mockery.Assertions`
* Added `Mockery.Assertions.refute_called/2` and `Mockery.Assertions.refute_called/3`
* Loosen elixir version requirement from `~> 1.3` to `~> 1.1`
