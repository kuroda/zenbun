---
title: "JS と Elixir の比較: 変数への再代入不可能性と値の不変性"
published: true
type: tech
emoji: 🪄
topics: ["JavaScript", "Elixir"]
---

JavaScript の `const` は、再代入のできない変数を宣言するためのキーワードです。例えば、次のプログラムを Node.js 上で実行するとエラー `TypeError` が発生します。

```javascript
const number = 1
number = number + 1
console.log(number)
```

変数 `number` への再代入を許すには、`const` ではなく `let` で変数を宣言する必要があります。

```javascript
let number = 1
number = number + 1
console.log(number)
```

では、次の JavaScript プログラムはエラーを発生させるでしょうか。

```javascript
const number = 1
number++
console.log(number)
```

答えは「はい」です。同じエラー `TypeError` が発生します。これは意外な結果かもしれません。演算子 `++` が変数が参照している整数に直接 1 を加えているのなら、変数への再代入は発生していないと考えてもよさそうです。しかし、そうではありません。`number++` は `number = number + 1` と実質的に同じなのです。

次の JavaScript プログラムはどうでしょうか。

```javascript
const arr = [1, 2, 3]
arr.push(4)
console.log(arr)
```

これは正常に実行され、ターミナル上には `[ 1, 2, 3, 4 ]` と表示されます。変数 `arr` が参照する配列 `[1, 2, 3]` の末尾に要素 `4` が加えられています。

ここは、JavaScript の初学者が誤解しやすいところです。キーワード `const` は、変数への再代入を禁止するだけであって、変数が参照しているオブジェクトの改変は禁止しません。

----

プログラミング言語 Elixir の特徴のひとつは、値の不変性（immutability）です。次のプログラムをご覧ください。

```elixir
list = [1, 2, 3]
list = list ++ [4]
IO.inspect(list)
```

2 つのリスト `[1, 2, 3]` と `[4]` を演算子 `++` で連結して `[1, 2, 3, 4]` を作り、変数 `list` に再代入しています。

JavaScript とは異なり、Elixir にはリストに要素を加えるための構文がありません。リストを含むすべての値は不変です。また、JavaScript とは異なり、Elixir には変数への再代入を禁ずる方法がありません。

ちなみに、Elixir の世界では「変数 `x` に値を代入する」という表現はあまり使いません。「変数 `x` と値を束縛する」という表現の方が好まれます。

----

さて、Elixir には変数への再代入（変数の再束縛）を禁ずる方法がない、と書きましたが、本当は「変数への再代入は発生しない」と表現するのが正確です。

Elixir コンパイラはさきほど挙げたプログラムを次のものと同等なものと解釈します。

```elixir
list = [1, 2, 3]
list1 = list ++ [4]
IO.inspect(list1)
```

つまり、変数の名前が衝突しないように、コンパイラが内部的に名前を読み替えてしまうのです。

この辺りの事情を理解するのによい例が、次の Elixir プログラムです。

```elixir
list = [1, 2, 3]
list = [1, 2, 3, 4]
IO.inspect(list)
```

これを実行するとエラーは発生しませんが、1 行目に関して「変数 `list` が使われていない」という警告が出ます。つまり、3 行目の変数 `list` は 2 行目の変数 `list` を指していて、1 行目の変数 `list` とは無関係なのです。

一見すると、次の JavaScript でも同じことをしています。

```javascript
let arr = [1, 2, 3]
arr = [1, 2, 3, 4]
console.log(arr)
```

1 行目の代入は完全に無駄ですが、このプログラムを実行しても警告は一切出ません。

----

JavaScript で「値の不変性」を実現するには、次のように `Object.freeze()` メソッドを用います。

```javascript
const arr = [1, 2, 3]
Object.freeze(arr)
arr.push(4)
console.log(arr)
```

このプログラムを実行すると `TypeError` エラーが発生します。

Elixir ではこの種のエラーは発生しません。なぜなら、値を直接書き換えるような構文自体が存在しないからです。
