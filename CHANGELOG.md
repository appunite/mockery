# Changelog

## 1.1.0
* Added `Mockery.mock/2` (`Mockery.mock/3` value defaults to `:mocked`)

## 1.0.1
* Fixed issue when mocking with `nil` or `false`

## 1.0.0
* Added `use Mockery` for importing both `Mockery` and `Mockery.Assertions`
* Added `Mockery.Assertions.refute_called/2` and `Mockery.Assertions.refute_called/3`
* Loosen elixir version requirement from `~> 1.3` to `~> 1.1`
