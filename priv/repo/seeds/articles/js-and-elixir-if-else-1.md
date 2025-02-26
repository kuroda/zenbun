---
title: "JS と Elixir の比較: if...else 文と if マクロ (1)"
published: true
type: tech
emoji: 🪄
topics: ["JavaScript", "Elixir"]
---

本稿では、JavaScript の `if...else` 文と Elixir の `if` マクロを比較します。

JavaScript の [if...else 文](https://developer.mozilla.org/ja/docs/Learn/JavaScript/Building_blocks/conditionals)の基本的な構文は次の通りです。

```javascript
if (条件式) {
  A
} else {
  B
}
```

「条件式」が成立したら A が実行され、そうでなければ B が実行されます。何をもって条件式が成功したとされるのかは少しややこしいです。JavaScript では以下の値が「偽とみなされる値（falsy value）」です。

> false, 0, -0, 0n, "", null, undefined, NaN

「条件式」がこれらの値を返さなければ条件式が成立します。

----

Elixir には「条件文」という概念はありません。しかし、類似の働きをする [if マクロ](https://hexdocs.pm/elixir/Kernel.html#if/2) が存在します。「マクロ」という言葉については気にせずに読み進めてください。

`if` マクロ は次のように利用します。

```elixir
if 条件式 do
  A
else
  B
end
```

「条件式」が成立したら A が評価され、そうでなければ B が評価されます。Elixir では以下の値が「偽とみなされる値」です。

> false, nil

「条件式」がこれらの値を返さなければ条件式が成立します。

----

私は、JavaScript の `if...else` 文については「実行」、Elixir の `if` マクロについては「評価」という言葉を使いました。この言葉の使い分けには重要な意味があります。プログラミングにおいて「評価する（evaluate）」とは、式の値を決定するという意味です。

次の Elixir のプログラムをご覧ください。

```elixir
x = 100

y =
  if x > 0 do
    "A"
  else
    "B"
  end

IO.puts(y)
```

このプログラムにおいて、`if` から `end` までの部分がひとつの「式」を構成します。条件式 `x > 0` が成立するとき、この式の値が `"A"` と評価され、それが変数 `y` にセットされます。条件式 `x > 0` が成立しないときは、`"B"` が変数 `y` にセットされます。このプログラムを実行するとターミナルには `A` と出力されます。

他方、JavaScript の `if...else` 文では次のようには書けません。

```javascript
const x = 100

const y =
  if (x > 0) {
    "A"
  }
  else {
    "B"
  }

console.log(y)
```

`if` のところで構文エラーが発生します。`if...else` 文はプログラムの流れを制御するためのものです。文全体が評価されて値を返すようには作られていません。

そこで、次のように書く必要があります。

```javascript
const x = 100
let y

if (x > 0) {
  y = "A"
}
else {
  y = "B"
}

console.log(y)
```

----

ところで、JavaScript にも Elixir の `if` マクロと同様の働きをする構文があります。[条件 (三項) 演算子](https://developer.mozilla.org/ja/docs/Web/JavaScript/Reference/Operators/Conditional_operator)です。これを用いると、直前のプログラムは次のように書き換えることができます。

```javascript
const x = 100
const y = x > 0 ? "A" : "B"
console.log(y)
```

条件 (三項) 演算子は、`?` と `:` という2つの記号から構成される風変わりな演算子です。`?` の左に条件式を書き、`?` と `:` の間に条件式が成立したときに評価される式、`:` の右に条件式が成立しないときに評価される式を書きます。

[JS と Elixir の比較: if...else 文と if マクロ (2)](https://zenn.dev/tkrd/articles/js-and-elixir-if-else-2)へ続きます。
