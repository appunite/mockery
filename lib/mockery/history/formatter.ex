defmodule Mockery.History.Formatter do
  @moduledoc false

  def format(pattern_ast, call, pins, binding) do
    error = %ExUnit.AssertionError{
      left: pattern_ast,
      right: call,
      context: {:match, parse_pins(pins, binding)},
      message: ExUnit.AssertionError.no_value(),
      expr: ExUnit.AssertionError.no_value(),
      args: ExUnit.AssertionError.no_value(),
      doctest: ExUnit.AssertionError.no_value()
    }

    parts = ExUnit.Formatter.format_assertion_diff(error, 6, 300, &formatter_callback/2)

    """
    args: #{parts[:left]}
    call: #{parts[:right]}
    """
  end

  defp colors do
    Keyword.merge(IO.ANSI.syntax_colors(),
      diff_insert: :red,
      diff_insert_whitespace: [:red, :faint],
      diff_delete: :green,
      diff_delete_whitespace: [:green, :faint]
    )
  end

  defp formatter_callback(:diff_enabled?, _) do
    true
  end

  defp formatter_callback(key, doc)
       when key in [:diff_insert, :diff_insert_whitespace, :diff_delete, :diff_delete_whitespace] do
    Inspect.Algebra.color(doc, key, %Inspect.Opts{syntax_colors: colors()})
  end

  defp formatter_callback(_key, value) do
    value
  end

  defp parse_pins(pins, binding) do
    for pin <- pins do
      {{pin, nil}, binding[pin]}
    end
  end
end
