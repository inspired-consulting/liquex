defmodule Liquex.Parser.Tag.Conditional do
  import NimbleParsec

  alias Liquex.Parser.Tag
  alias Liquex.Parser.Literal

  @spec operator(NimbleParsec.t()) :: NimbleParsec.t()
  def operator(combinator \\ empty()) do
    combinator
    |> choice([
      string("=="),
      string("!="),
      string(">="),
      string("<="),
      string(">"),
      string("<"),
      string("contains")
    ])
    |> map({String, :to_existing_atom, []})
  end

  @spec boolean_operator(NimbleParsec.t()) :: NimbleParsec.t()
  def boolean_operator(combinator \\ empty()) do
    combinator
    |> choice([
      replace(string("and"), :and),
      replace(string("or"), :or)
    ])
  end

  @spec boolean_operation(NimbleParsec.t()) :: NimbleParsec.t()
  def boolean_operation(combinator \\ empty()) do
    combinator
    |> tag(Literal.argument(), :left)
    |> ignore(Literal.whitespace())
    |> unwrap_and_tag(operator(), :op)
    |> ignore(Literal.whitespace())
    |> tag(Literal.argument(), :right)
    |> wrap()
  end

  @spec boolean_expression(NimbleParsec.t()) :: NimbleParsec.t()
  def boolean_expression(combinator \\ empty()) do
    combinator
    |> choice([boolean_operation(), Literal.literal(), Literal.argument()])
    |> ignore(Literal.whitespace())
    |> repeat(
      boolean_operator()
      |> ignore(Literal.whitespace())
      |> choice([boolean_operation(), Literal.literal(), Literal.argument()])
    )
  end

  @spec if_expression(NimbleParsec.t()) :: NimbleParsec.t()
  def if_expression(combinator \\ empty()) do
    combinator
    |> if_tag()
    |> repeat(elsif_tag())
    |> optional(else_tag())
    |> ignore(Tag.tag_directive("endif"))
  end

  @spec unless_expression(NimbleParsec.t()) :: NimbleParsec.t()
  def unless_expression(combinator \\ empty()) do
    combinator
    |> unless_tag()
    |> repeat(elsif_tag())
    |> optional(else_tag())
    |> ignore(Tag.tag_directive("endunless"))
  end

  @spec case_expression(NimbleParsec.t()) :: NimbleParsec.t()
  def case_expression(combinator \\ empty()) do
    combinator
    |> case_tag()
    |> ignore(Literal.whitespace())
    |> times(when_tag(), min: 1)
    |> optional(else_tag())
    |> ignore(Tag.tag_directive("endcase"))
  end

  def else_tag(combinator \\ empty()) do
    combinator
    |> ignore(Tag.tag_directive("else"))
    |> tag(parsec(:document), :contents)
    |> tag(:else)
  end

  defp if_tag(combinator) do
    combinator
    |> expression_tag("if")
    |> tag(parsec(:document), :contents)
    |> tag(:if)
  end

  defp unless_tag(combinator) do
    combinator
    |> expression_tag("unless")
    |> tag(parsec(:document), :contents)
    |> tag(:unless)
  end

  defp elsif_tag(combinator \\ empty()) do
    combinator
    |> expression_tag("elsif")
    |> tag(parsec(:document), :contents)
    |> tag(:elsif)
  end

  def case_tag(combinator \\ empty()) do
    combinator
    |> ignore(string("{%"))
    |> ignore(Literal.whitespace())
    |> ignore(string("case"))
    |> ignore(Literal.whitespace(empty(), 1))
    |> concat(Literal.argument())
    |> ignore(Literal.whitespace())
    |> ignore(string("%}"))
    |> tag(:case)
  end

  defp when_tag(combinator \\ empty()) do
    combinator
    |> ignore(string("{%"))
    |> ignore(Literal.whitespace())
    |> ignore(string("when"))
    |> ignore(Literal.whitespace(empty(), 1))
    |> tag(Literal.literal(), :expression)
    |> ignore(Literal.whitespace())
    |> ignore(string("%}"))
    |> tag(parsec(:document), :contents)
    |> tag(:when)
  end

  @spec expression_tag(NimbleParsec.t(), String.t()) :: NimbleParsec.t()
  defp expression_tag(combinator, tag_name) do
    combinator
    |> ignore(string("{%"))
    |> ignore(Literal.whitespace())
    |> ignore(string(tag_name))
    |> ignore(Literal.whitespace())
    |> tag(boolean_expression(), :expression)
    |> ignore(Literal.whitespace())
    |> ignore(string("%}"))
  end
end