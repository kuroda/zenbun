---
title: "Elixir: 文字列を無名関数に変換する"
published: true
type: tech
emoji: 🫐
topics: ["Elixir"]
---

# 概要

本稿では、プログラミング言語 Elixir の関数 [Code.eval_string/3](https://hexdocs.pm/elixir/Code.html#eval_string/3) を利用して、文字列を無名関数に変換する方法について解説します。

# 関数 Code.eval_string/2 を使ってみる

次の Elixir スクリプト `eval_string1.exs` をご覧ください。

```elixir:eval_string1.exs
{f, _binding} = Code.eval_string("fn a, b -> a + b * 2 end")
result = f.(3, 2)
IO.puts(result)
```

`elixir eval_string1.exs` コマンドでこのスクリプトを実行すると、ターミナルには「7」と出力されます。

関数 `Code.eval_string/3`（第 2 引数と第 3 引数は省略可）は、引数に文字列を取り、その文字列を Elixir コードとして評価し、2 要素タプルを返します。タプルの第 1 要素が評価の結果です。

ここでは `fn a, b -> a + b * 2 end` という Elixir コードが評価され、結果の無名関数が変数 `f` にセットされます。そして、`f.(3, 2)` により式 `3 + 2 * 2` が評価されて、変数 `result` には 7 がセットされます。

# 例外処理(1)

次の Elixir スクリプト `eval_string2.exs` をご覧ください。

```elixir:eval_string2.exs
{result, all_errors_and_warnings} =
  Code.with_diagnostics(fn ->
    try do
      {f, _binding} = Code.eval_string("fn a, b -> a + c * 2 end")
      dbg f
    rescue
      e in CompileError -> e
    end
  end)

IO.inspect(result)
IO.inspect(all_errors_and_warnings)
```

関数 `Code.eval_string/3` に文字列 `"fn a, b -> a + c * 2 end"` を渡すと、例外 `CompileError` が発生します。なぜなら、定義されていない変数 `c` が使われているためです。

ただし、例外 `CompileError` にはエラーに関する詳しい情報が含まれません。それを得るには、`try do ... rescue ... end` 全体を関数 [Code.with_diagnostics/2](https://hexdocs.pm/elixir/Code.html#with_diagnostics/2)で囲む必要があります。

`elixir eval_string2.exs` コマンドでこのスクリプトを実行すると、ターミナルには次のように出力されます。

```
%CompileError{
  file: "/home/kuroda/temp/eval_string2.exs",
  line: 0,
  description: "cannot compile file (errors have been logged)"
}
[
  %{
    message: "undefined variable \"c\"",
    position: 4,
    file: "/home/kuroda/temp/eval_string3.exs",
    stacktrace: [],
    source: "/home/kuroda/temp/eval_string3.exs",
    span: nil,
    severity: :error
  }
]
```

# 例外処理(2)

次の Elixir スクリプト `eval_string3.exs` をご覧ください。

```elixir:eval_string3.exs
{result, all_errors_and_warnings} =
  Code.with_diagnostics(fn ->
    try do
      {f, _binding} = Code.eval_string("fn a, b -> a + (b end")
      dbg f
    rescue
      e in MismatchedDelimiterError -> e
    end
  end)

IO.inspect(result)
IO.inspect(all_errors_and_warnings)
```

関数 `Code.eval_string/3` に文字列 `"fn a, b -> a + (b end"` を渡すと、例外 `MismatchedDelimiterError` が発生します。なぜなら括弧が閉じられていないからです。

`elixir eval_string3.exs` コマンドでこのスクリプトを実行すると、ターミナルには次のように出力されます。

```
%MismatchedDelimiterError{
  file: "/home/kuroda/temp/eval_string3.exs",
  line: 17,
  column: 16,
  end_line: 17,
  end_column: 19,
  opening_delimiter: :"(",
  closing_delimiter: :end,
  expected_delimiter: :")",
  snippet: "fn a, b -> a + (b end",
  description: "unexpected reserved word: end"
}
[]
```

# モジュール化

ここまでに得た知識を利用して、モジュールとして整えましょう。

次の Elixir スクリプト `eval_func.exs` をご覧ください。

```elixir
defmodule K do
  def eval_func(expr) do
    {result, all_errors_and_warnings} =
      Code.with_diagnostics(fn ->
        try do
          {f, _} = Code.eval_string("fn a, b -> #{expr} end")
          f
        rescue
          e in [CompileError, MismatchedDelimiterError] -> e
        end
      end)

    case {result, all_errors_and_warnings} do
      {f, []} when is_function(f) ->
        {:ok, f}

      {%MismatchedDelimiterError{}, _} ->
        {:error, "mismatched delimiter"}

      {_, all_errors_and_warnings} ->
        message =
          all_errors_and_warnings
          |> Enum.map(fn error_and_warning ->
            Map.get(error_and_warning, :message)
          end)
          |> Enum.join("; ")

        {:error, message}
    end
  end
end

expressions = [
  "a + b",
  "a * b + 1",
  "a + c",
  "a + (b"
]

for expr <- expressions do
  case K.eval_func(expr) do
    {:ok, f} -> IO.puts(f.(3, 5))
    {:error, message} -> IO.puts("Warnings and Errors: #{message}")
  end
end
```

`elixir eval_func.exs` コマンドでこのスクリプトを実行すると、ターミナルには次のように出力されます。

```
8
16
Warnings and Errors: undefined variable "c"
Warnings and Errors: mismatched delimiter
```

# 【参考】無名関数とバイナリを相互変換する

本稿のテーマとは直接的な関係を持ちませんが、参考として無名関数とバイナリを相互変換できることを紹介します。

次の Elixir スクリプト `eval_string4.exs` をご覧ください。

```elixir:eval_string4.exs
{f, _binding} = Code.eval_string("fn a, b -> a + b * 2 end")
g = :erlang.term_to_binary(f)
IO.inspect(g)
h = :erlang.binary_to_term(g)
result = h.(3, 2)
IO.puts(result)
```

`elixir eval_string4.exs` コマンドでこのスクリプトを実行すると、ターミナルには次のように出力されます。

```
<<131, 112, 0, 0, 1, 43, 2, 74, 179, 14, 23, 76, 2, 152, 184, 122, 207, 206, 42,
  63, 68, 21, 64, 0, 0, 0, 41, 0, 0, 0, 1, 119, 8, 101, 114, 108, 95, 101, 118,
  97, 108, 97, 41, 98, 2, 85, 152, 112, 88, 119, ...>>
7
```

関数 [:erlang.term_to_binary/1](https://www.erlang.org/doc/apps/erts/erlang.html#term_to_binary/1) は、Elixir のあらゆる値をバイナリに変換します。ここでは、変数 `f` にセットされた無名関数をバイナリに変換して変数 `g` にセットし、`IO.inspect(g)` でターミナルに出力しています。`<<131, 112, 0, ...` がそのバイナリです。

このバイナリを元に戻すには、関数 [:erlang.binary_to_term/1](https://www.erlang.org/doc/apps/erts/erlang.html#binary_to_term/1) を利用します。ここでは、変数 `g` にセットされたバイナリを無名関数に戻して変数 `h` にセットし、式 `h.(3, 2)` を評価して 7 という値を得ています。

このバイナリはファイルやデータベースに保存できるので、活用方法がいろいろとあります。例えば、Web 系の業務システムにおいて使用する計算式をユーザーにフォームから設定させることができます。
