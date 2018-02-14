use Mix.Config

config :mockery, :integration_test, {Mockery.Proxy, IntegrationTest.Mocked, nil}
