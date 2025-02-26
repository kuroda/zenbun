---
title: Elixir チートシート
published: true
type: tech
emoji: 🫐
topics: ["elixir"]
---

# この文書について

本稿は、もともと Zenn Book [Phoenix LiveView 入門①: はじめの一歩](https://zenn.dev/tkrd/books/live_view_primer_1)の chapter 01「イントロダクション」の Section 2 であったものを Zenn Article として独立させたものです。

# コメント

```elixir
# Comment
```

# 変数

```elixir
x = 1
x = x + 1
_unused_var = x + 1
```

# アトム

```elixir
:index
Index
:"123"
```

# 文字列

```elixir
"Hello"
```

:::details 文字リスト
`'Hello'` のようにシングルクォートで囲むと**文字リスト**（charlist）になります。Erlang の関数を呼び出すとき以外には、ほぼ使われません。
:::

# 文字列への式の埋め込み

```elixir
name = "Alice"
message = "Hi, #{name}!"
IO.inspect(message) # => "Hi, Alice"
```

# タプル

```elixir
{"Alice", 1, true}
```

# リスト

```elixir
users = ["Bob", "Carol"]
users = ["Alice" | users]
users = users ++ ["David"]
IO.inspect(users) # => ["Alice", "Bob", "Carol", "David"]
```

# マップ

```elixir
data = %{"Alice" => 100, "Bob" => 20, "Carol" => 47}
score = Map.get(data, "Bob")
IO.inspect(score) # => 20

alice = %{name: "Alice", score: 100}
IO.inspect(alice.score) # => 100
```

# シギル（シジル）

```elixir
~s<Sum: #{1 + 1}!> # => "Sum: 2"
~S(Sum: #{1 + 1}!) # => "Sum: #{1 + 1}"
~w(alice bob carol) # => ["alice", "bob", "carol"]
~w/alice bob carol/a # => [:alice, :bob, :carol]
~r"[a-z][0-9a-z]*" # => 正規表現 [a-z][0-9a-z]*
```

:::details シギルのデリミタ
`~s<Sum: #{1 + 1}!>` に含まれる `<` と `>` のペアはシギルの始端と終端を表し、**デリミタ**（delimiters）と呼ばれます。

以下の 8 種類の文字ペアをシギルのデリミタとして使用できます：

* `<`, `>`
* `{`, `}`
* `[`, `]`
* `(`, `)`
* `|`, `|`
* `/`, `/`
* `"`, `"`
* `'`, `'`
:::

# パターンマッチング

```elixir
pair = {"Alice", 100}
{_name, score} = pair
IO.inspect(score) # => 100
```

```elixir
user = %{name: "Alice", score: 100}
%{name: name} = user
IO.inspect(name) # => "Alice"
```

# 条件分岐

```elixir
if x do
  "A"
end
```

```elixir
if x do
  "A"
else
  "B"
end
```

```elixir
cond do
  x == 1 -> "A"
  x == 2 -> "B"
  true -> "C"
end
```

```elixir
case x do
  1 -> "A"
  2 -> "B"
  _ -> "C"
end
```

# 関数 Enum.map/2

```elixir
numbers = [1, 2, 3]
results = Enum.map(numbers, &(&1 * 2))
IO.inspect(results) # => [2, 4, 6]
```

# 内包表記

```elixir
numbers =
  for n <- [0, 1, 2, 3, 4] do
    n + 1
  end

IO.inspect(numbers) # => [1, 2, 3, 4, 5]
```

```elixir
data = %{"Alice" => 100, "Bob" => 20, "Carol" => 47}

scores =
  for {_name, score} <- data do
    score
  end

IO.inspect(scores) # => [100, 20, 47]
```

# 範囲

```elixir
numbers =
  for n <- 0..4 do
    n + 1
  end

IO.inspect(numbers) # => [1, 2, 3, 4, 5]
```

# モジュール

```elixir
defmodule Robot do
end
```

# 関数定義

```elixir
defmodule Robot do
  def add(a, b) do
    a + b
  end
end

Robot.add(2, 3) # => 5
```

```elixir
defmodule Droid do
  def add(a, b), do: a + b
end

Droid.add(2, 3) # => 5
```

:::details アリティ
関数の引数の個数を**アリティ**（arity）と呼びます。

上記の関数を API ドキュメント等で参照するとき、`Robot.add/2` のように表記します。末尾の `/2` はアリティを示します。
:::

:::details マクロ
コンパイル時に行われる一連の処理に名前を付けたものを**マクロ**と呼びます。本巻では（おそらく本シリーズを通じて）マクロを定義する方法について説明しません。しかし、定義済みのマクロを呼び出す機会は頻繁にあります。

関数と同様にマクロは特定のモジュールに所属します。マクロの呼び出し方は関数と同じです。
:::

# パイプ演算子

```elixir
str = "Alice Bob Carol"

result =
  str
  |> String.split(" ")
  |> Enum.map(fn name -> String.first(name) end)
  |> Enum.join("-")

IO.inspect(result) # => "A-B-C"
```

# 無名関数

```elixir
add = fn a, b -> a + b end
r = add.(2, 3)
IO.inspect(r) # => 5
```

# & 記法

```elixir
add = &(&1 + &2)
r = add.(2, 3)
IO.inspect(r) # => 5
```

```elixir
names = ~w(Alice Bob Carol)
initials = Enum.map(names, &String.first/1)
IO.inspect(initials) # => ["A", "B", "C"]
```

# ガード

```elixir
defmodule Robot do
  def increment(a, b) when b > 0, do: a + b
  def increment(a, _), do: a
end

Robot.increment(2, 3) # => 5
Robot.increment(2, -3) # => 2
```

# モジュール属性

```elixir
defmodule Robot do
  @name "Alice"

  def greeting do
    "Hi, my name is #{@name}!"
  end
end

IO.inspect(Robot.greeting()) # => "Hi, my name is Alice!"
```

:::details 定数としてのモジュール属性
モジュールの定義中で `@name "Alice"` のように書くと、`name` という名前の**モジュール属性**に `"Alice"` という値が設定されます。モジュール属性は、コンパイル時に「定数」として展開されます。

`@name = "Alice"` のように等号（`=`）を使わない点に注意してください。

`@doc` のようないくつかのモジュール属性には特別な役割が与えられています。
:::

# 構造体

```elixir
defmodule User do
  defstruct name: nil, score: 0
end

u = %User{name: "Alice", score: 100}
IO.inspect(u.name) # => "Alice"
u = %{u | score: 200}
IO.inspect(u.score) # => 200
```

:::details 構造体とは
**構造体**とは、マップと同様に複数個の値を集合として扱うためのデータ型です。

構造体の各値にはユニークな**キー**が割り当てられます。構造体のキーは**フィールド**とも呼ばれます。

マップとは次の3点で異なります。

* 構造体のキーは必ずアトムである。
* 構造体にキーを追加できない。
* 構造体からキーを削除できない。

構造体はモジュール定義の中で `defstruct` マクロにより定義されます。上記の例ではフィールド `name` と `score` を持つ構造体を定義しています。フィールド `name` のデフォルト値は `nil`, フィールド `score` のデフォルト値は 0 です。モジュール `User` で定義された構造体は、「`User` 構造体」と呼ばれます。
:::
