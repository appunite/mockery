locals_without_parens = [
  defmock: 2,
  defmock: 3,
  assert_called!: 2,
  assert_called!: 3,
  refute_called!: 2,
  refute_called!: 3
]

[
  inputs: ["{mix,.formatter,.credo}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  locals_without_parens: locals_without_parens,
  export: [
    locals_without_parens: locals_without_parens
  ]
]
