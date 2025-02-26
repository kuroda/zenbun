---
title: "JS と Elixir の比較: switch 文と case マクロ"
published: true
type: tech
emoji: 🪄
topics: ["JavaScript", "Elixir"]
---

本稿では、JavaScript の `switch` 文と Elixir の `case` マクロを比較します。

JavaScript の [switch 文](https://developer.mozilla.org/ja/docs/Web/JavaScript/Reference/Statements/switch)の基本的な構文は次の通りです。

```javascript
switch (式0) {
  case 式1:
    文1
    break
  case 式2:
    文2
    break

  (省略)

  case 式n:
    文n
    break
  default:
    文z
}
```

「式0」を評価した値を X とします。「式1」の値が X に等しい場合、「文1」が実行されて `switch` 文全体が終了します。「式1」の値が X に等しくない場合、「式2」の値と X が比較されます。「式2」の値と X が等しい場合、「文2」が実行されて `switch` 文全体が終了します。同様に、「式3」、「式4」、と値の照合が行われていき、「式n」の値と X が等しくない場合、「文z」が実行されます。

次に示す JavaScript プログラムを実行すると、ターミナルには「Zero」と出力されます。

```javascript
let n = 0

switch (n) {
  case 0:
    console.log("Zero")
    break
  case 1:
    console.log("One")
    break
  default:
    console.log("Many")
}
```

----

Elixir の [case マクロ](https://hexdocs.pm/elixir/Kernel.SpecialForms.html#case/2) は、JavaScript の switch 文に類似した働きをします。「マクロ」という言葉については気にせずに読み進めてください。

`case` マクロ は次のように利用します。

```elixir
case 式0 do
  式1a -> 式1b
  式2a -> 式2b

  (省略)

  式na -> 式nb
  _ -> 式zb
end
```

「式0」を評価した値を X とします。「式1a」の値が X に等しい場合、「式1b」が評価されます。「式1a」の値が X に等しくない場合、「式2a」の値と X が比較されます。「式2a」の値と X が等しい場合、「式2b」が評価されます。同様に、「式3」、「式4」、と値の照合が行われていき、「式na」の値と X が等しくない場合、「式zb」が評価されます

私は、JavaScript の `switch` 文については「実行」、Elixir の `case` マクロについては「評価」という言葉を使いました。この言葉の使い分けには重要な意味があります。プログラミングにおいて「評価する（evaluate）」とは、式の値を決定するという意味です。

次の Elixir のプログラムをご覧ください。

```elixir
n = 0

m =
  case n do
    0 -> "Zero"
    1 -> "One"
    _ -> "Many"
  end

IO.puts(m)
```

このプログラムにおいて、`case` から `end` までの部分がひとつの「式」を構成します。条件式 `n == 0` が成立するとき、この式の値が `"Zero"` と評価され、それが変数 `m` にセットされます。条件式 `n == 1` が成立するとき、この式の値が `"One"` と評価され、それが変数 `m` にセットされます。`n` が 0 でも 1 でもなければ、変数 `m` には `"Many"` がセットされます。このプログラムを実行するとターミナルには `Zero` と出力されます。

他方、JavaScript の `switch` 文では次のようには書けません。

```javascript

let n = 0

let m =
  switch (n) {
    case 0:
      "Zero"
      break
    case 1:
      "One"
      break
    default:
      "Many"
  }

console.log(m)
```

`switch` のところで構文エラーが発生します。`switch` 文はプログラムの流れを制御するためのものです。文全体が評価されて値を返すようには作られていません。

そこで、次のように書く必要があります。

```javascript
let n = 0
let m

switch (n) {
  case 0:
    m = "Zero"
    break
  case 1:
    m = "One"
    break
  default:
    m = "Many"
}

console.log(m)
```

----

ところで、JavaScript の `switch` 文には `break` 文で処理を止めないと、次以降の `case` 節に進む、という仕様があります。この仕様は「落下（fall-through）」と呼ばれますが、初心者泣かせの仕様として有名です。

試しに、直前の JavaScript プログラムを次のように書き換えてみましょう。

```javascript
let n = 0
let m

switch (n) {
  case 0:
    m = "Zero"
  case 1:
    m = "One"
    break
  default:
    m = "Many"
}

console.log(m)
```

最初の `case` 節の末尾から `break` 文を除去しました。すると、このプログラムは `One` を出力します。

----

この「欠陥」を補うひとつの方法は、`switch` 文を内包する関数を定義するというものです。

```javascript
function switchCase(n) {
  switch (n) {
    case 0:
      return "Zero"
    case 1:
      return "One"
    default:
      return"Many"
  }
}

let n = 0
let m = switchCase(n)

console.log(m)
```

`break` 文の代わりに `return` 文を使うことにより `switch` 文を抜けつつ、関数から値を返しています。

さらに、[即時実行関数式](https://developer.mozilla.org/ja/docs/Glossary/IIFE)を利用すると、次のように書き換えられます。

```javascript
let n = 0

let m =
  (() => {
    switch (n) {
      case 0:
        return "Zero"
      case 1:
        return "One"
      default:
        return"Many"
    }
  })(n)

console.log(m)
```

慣れないと括弧が多くて読みづらく思えるかもしれませんが、こうすると Elixir の `case` マクロに類似した書き方が可能になります。

ただし、この書き方を採用した場合でも、`return` 文を書き忘れると挙動がおかしくなる、という問題は残っています。`return` 文がなくても文法的には正しいので、エラーや警告は出力されません。

----

さて、Elixir の `case` マクロでは[パターンマッチング](https://elixir-lang.jp/getting-started/pattern-matching.html)が利用できるため、JavaScript の `swtich` 文よりも強力です。次の Elixir プログラムをご覧ください。

```elixir
code_number = "x-123"

code_number =
  case code_number do
    "x-" <> n -> n <> "-A"
    "y-" <> n -> n <> "-B"
    "z-" <> n -> n <> "-C"
    _ -> "Unknown"
  end

IO.puts(code_number)
```

5 行目は「`code_number` の最初の2文字が `x-` だったら、変数 `n` に残りの部分をセットして `->` の右辺を評価する」という意味になります。上記のプログラムを実行すると `123-A` と出力されます。

もうひとつ例を示します。

```elixir
list = [1, 2, 3]

category =
  case list do
    [] -> "Empty"
    [0, _, _] -> "Starting from zero"
    [1, _, _] -> "Starting from one"
    _ -> "Other"
  end

IO.puts(category)
```

`case` マクロの中でリストに対するパターンマッチングを行っています。6 行目は「`list` が要素数 3 のリストであり、その第 1 引数が 0 だったら、`"Starting from zero"` を返す」という意味になります。上記のプログラムを実行すると `Starting from one` と出力されます。
