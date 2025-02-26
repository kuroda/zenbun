---
title: "JS と Elixir の比較: if...else 文と if マクロ (2)"
published: true
type: tech
emoji: 🪄
topics: ["JavaScript", "Elixir"]
---

[前回の記事](https://zenn.dev/tkrd/articles/js-and-elixir-if-else-1)の続きです。JavaScript の `if...else` 文と Elixir の `if` マクロを比較します。

JavaScript の [if...else 文](https://developer.mozilla.org/ja/docs/Learn/JavaScript/Building_blocks/conditionals)は次のように `else` 以下を省略できます。

```javascript
if (条件式) {
  A
}
```

「条件式」が成立したら A が実行され、そうでなければ何も起きません。

同様に、Elixir の `if` マクロでも `else` を省略できます。

```elixir
if 条件式 do
  A
end
```

「条件式」が成立したら A が評価されて式 `if ... end` 全体の値となります。

重要なのは、「条件式」が成立しない場合は `nil` が式全体の値となるということです。つまり、上記のプログラムは次のものと同値です。


```elixir
if 条件式 do
  A
else
  nil
end
```

`false` が式全体の式になると誤解しないよう注意してください。

----

JavaScript の `if...else` 文では次のように `else if` を用いて複数の条件式による分岐を実現できます。

```javascript
if (条件式1) {
  A
}
else if (条件式2) {
  B
}
else if (条件式3) {
  C
}
else {
  D
}
```

以下のように処理が進みます。

* 「条件式1」が成立したら A が実行される。
* 「条件式1」が成立せずに「条件式2」が成立したら B が実行される。
* 「条件式1」と「条件式2」が成立せずに「条件式3」が成立したら C が実行される。
* いずれの条件式も成立しなければ D が実行される。

意外に思われるかもしれませんが、Elixir の `if` マクロには JavaScript の `else if` に相当する書き方がありません。仕方がないので、次のように入れ子にして書くことになります。

```elixir
if 条件式1 do
  A
else
  if 条件式2 do
    B
  else
    if 条件式3 do
      C
    else
      D
    end
  end
end
```

しかし、`cond` マクロを使えば入れ子構造を使わずに書けます。


```elixir
cond do
  条件式1 -> A
  条件式2 -> B
  条件式3 -> C
  true -> D
end
```

`cond` マクロは `if` マクロの上位互換です。本来、`cond` マクロがあれば `if` マクロは不要です。つまり、`if` マクロは人間にとっての読みやすさのために導入された書き方、いわゆる**糖衣構文**（syntactic sugar）です。条件がひとつしかないときは `if` マクロを使い、条件が複数あるときは `cond` マクロを使うとよいでしょう。

[JS と Elixir の比較: if...else 文と if マクロ (3)](https://zenn.dev/tkrd/articles/js-and-elixir-if-else-3)へ続きます。
