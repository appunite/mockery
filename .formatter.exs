locals_without_parens = [
  assert_called!: 2,
  assert_called!: 3,
  refute_called!: 2,
  refute_called!: 3
]

[
  inputs: ["{mix,.formatter,.credo}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  locals_without_parens: locals_without_parens,
  import_deps: [:mockery_macro],
  export: [
    locals_without_parens: locals_without_parens
  ]
]
