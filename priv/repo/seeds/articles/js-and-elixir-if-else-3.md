---
title: "JS と Elixir の比較: if...else 文と if マクロ (3)"
published: true
type: tech
emoji: 🪄
topics: ["JavaScript", "Elixir"]
---

[前回の記事](https://zenn.dev/tkrd/articles/js-and-elixir-if-else-2)の続き（最終回）です。JavaScript の `if...else` 文と Elixir の `if` マクロを比較します。

JavaScript の [if...else 文](https://developer.mozilla.org/ja/docs/Learn/JavaScript/Building_blocks/conditionals)は基本的な構文は次の通りです。

```javascript
if (条件式) {
  A
} else {
  B
}
```

しかし、A と B に単一の文しか含まれない時、中括弧は省略可能です。

```javascript
if (条件式)
  A
else
  B
```

Elixir の  [if マクロ](https://hexdocs.pm/elixir/Kernel.html#if/2) にも類似の省略記法が存在します。

```elixir
if 条件式,
  do: A,
  else: B
```

一行で書くこともできます。

```elixir
if 条件式, do: A, else: B
```

これは、[初回の記事](https://zenn.dev/tkrd/articles/js-and-elixir-if-else-1)で触れた JavaScript の[条件 (三項) 演算子](https://developer.mozilla.org/ja/docs/Web/JavaScript/Reference/Operators/Conditional_operator) によく似ています。

```javascript
条件式 ? A : B
```

直前の Elixir プログラムと比較してください。

----

★ここから先は、Elixir中上級者向けです★

ところで、Elixir には[パイプ演算子](https://elixirschool.com/ja/lessons/basics/pipe_operator)という面白い書き方があります。

次の例をご覧ください。

```elixir
x = "red green blue"
x = String.split(x, " ")
x = Enum.map(x, &String.capitalize/1)
x = Enum.join(x, "-")
IO.puts(x)
```

このプログラムでは、変数 `x` にセットした文字列をバケツリレー式にさまざまな関数で次々と変換していきます。最終的に変数 `x` には `"Red-Green-Blue"` という文字列がセットされます。

登場する関数の役割は次のとおりです:

* [String.split/3](https://hexdocs.pm/elixir/String.html#split/3) -- 文字列を分割
* [Enum.map/2](https://hexdocs.pm/elixir/Enum.html#map/2) -- リストの各要素を指定された関数で変換
* [String.capitalize/2](https://hexdocs.pm/elixir/String.html#capitalize/2) -- 先頭の文字を大文字にする
* [Enum.join/2](https://hexdocs.pm/elixir/Enum.html#join/2) -- リストを連結して文字列に変換

パイプ演算子 `|>` を用いると、このプログラムを次のように書き換えることができます。

```elixir
x =
  "red green blue"
  |> String.split(" ")
  |> Enum.map(&String.capitalize/1)
  |> Enum.join("-")

IO.puts(x)
```

パイプ演算子 `|>` の右辺にある関数は、左辺から渡される値を第 1 引数として受け取ります。

----

さて、パイプ演算子を使わないバージョンのプログラムを次のように書き換えます。


```elixir
x = "red green blue"
x = String.split(x, " ")
x = if length(x) < 5, do: ["black" | x], else: x
x = Enum.map(x, &String.capitalize/1)
x = Enum.join(x, "-")
IO.puts(x)
```

3 行目で、変数 `x` にセットされれているリストの要素数が 5 より小さいとき、リストの先頭に `"black"` という要素を加えています。変数 `list` にリストがセットされている時、`[e | list]` と書くとリストの先頭に `e` を加えたリストが返ってきます。

このプログラムをパイプ演算子 `|>` を用いた形に書き換えるにはどうすればよいでしょうか。`if` マクロは変換の対象を第1引数として取らないので不可能のように見えますが、関数 [then/2](https://hexdocs.pm/elixir/Kernel.html#then/2) を利用するとうまく行きます。

```elixir
x =
  "red green blue"
  |> String.split(" ")
  |> then(fn x -> if length(x) < 5, do: ["black" | x], else: x end)
  |> Enum.map(&String.capitalize/1)
  |> Enum.join("-")

IO.puts(x)
```

関数 `then/2` は、第 1 引数に任意の値、第 2 引数に無名関数を取ります。そして、第 1 引数を無名関数に渡してその結果を返します。

ごちゃごちゃして読みにくいと感じた方は、次のように書き換えてみてください。

```elixir
x =
  "red green blue"
  |> String.split(" ")
  |> then(fn x ->
    if length(x) < 5 do
      ["black" | x]
    else
      x
    end
  end)
  |> Enum.map(&String.capitalize/1)
  |> Enum.join("-")

IO.puts(x)
```
