---
title: "ActiveRecord と Ecto の比較④: 変更内容の追跡"
published: true
type: tech
emoji: 🫐
topics: ["Rails", "ActiveRecord", "Elixir", "Phoenix", "Ecto"]
---

本稿は、ActiveRecord と Ecto を比較するシリーズの第 4 回です。

ActiveRecord は Ruby on Rails の一部を構成するライブラリです。Ecto は Elixir のライブラリです。いずれもデータベースを操作するために利用します。

今回は、変更内容の追跡という観点から ActiveRecord と Ecto を比較します。[前回](https://zenn.dev/tkrd/articles/active-record-and-ecto-validations)の話の続きです。

----

本シリーズの[初回](https://zenn.dev/tkrd/articles/active-record-and-ecto-before-save)で書いたことの繰り返しになりますが、ActiveRecord の世界で「オブジェクト」と呼ばれているものが、Ecto では次の 2 つに分離されています。

* スキーマ構造体
* チェンジセット構造体

スキーマ構造体はデータベーステーブルのレコードに対応します。チェンジセット構造体はスキーマ構造体に対してどのような変更（changes）が加えられようとしているのかを表現するものです。チェンジセット構造体は、単に「チェンジセット」とも呼ばれます。

以下、具体的なコードを使ってこれらの概念について説明します。前提として、以下のような状態のデータベースが存在するとします。

* `users` というテーブルがある。
* それは主キーである整数型のカラム `id` と文字列型のカラム `name` を持つ。
* `users` テーブルにはレコード（行）が 1 つだけ挿入されており、それは `id` カラムの値が `1` で、`name` カラムの値が `"alice"` である。

では、次の Ruby コードをご覧ください：

```ruby
u = User.find(1)
u.assign_attributes({"name" => "bob"})
puts u.name
puts u.name_was
```

`User.find(1)` により、データベースの `users` テーブルから主キーの値が `1` であるレコードが取得されて、そのデータが変数 `u` にセットされます。これが ActiveRecord オブジェクトです。このオブジェクトに対して `assign_attributes` メソッドを呼び出すことにより、オブジェクトの状態が変化します。

ActiveRecord オブジェクトは、レコードそのものだけでなく、レコードに対して加えたい変更（changes）の情報を持っています。`u.name` は変更後の値（`"bob"`）を返すのに対し、`u.name_was` は変更前の値（`"alice"`）を返します。

続いて、次の Elixir コードをご覧ください。

```elixir
u = MyApp.Repo.get(Account.User, 1)
cs = Account.User.changeset(u, %{"name" => "bob"})
IO.puts Map.get(cs.changes, :name)
IO.puts cs.data.name
```

`MyApp.Repo.get(Account.User, 1)` により、データベースの `users` テーブルから主キーの値が `1` であるレコードが取得されて、そのデータが変数 `u` にセットされます。これがスキーマ構造体です。

そして、`Account.User` モジュールの関数 `changeset/2` により変数 `u` がチェンジセット構造体に変換され、それが変数 `cs` にセットされます。

チェンジセット構造体の `changes` フィールドには、次のようなマップがセットされています。

```elixir
%{name: "bob"}
```

このマップは、スキーマ構造体に対して加えようとしている変更を表しています。そこで、`Map.get(cs.changes, :name)` は変更後の値（`"bob"`）を返します。

また、チェンジセット構造体の `data` フィールドには、スキーマ構造体がそのままセットされています。そこで、`cs.data.name` は変更前の値（`"alice"`）を返します。チェンジセット構造体はスキーマ構造体のラッパーであるとみなすことができます。

なお、現実の開発では変更後の値を取得するのに `Map.get(cs.changes, :name)` という書き方はしません。`changes` フィールドのマップには変更されていない属性の値を含まないので、`name` 属性の値が変更されていない場合に `Map.get(cs.changes, :name)` は `nil` を返すからです。正しくは、`Ecto.Changeset.get_field(cs, :name)` のように書きます。

----

さて、ActiveRecord オブジェクトには `changed?` メソッドがあります。これはオブジェクト全体が変更されたかどうかを `true` または `false` で返します。

Ecto で同様のことを行うには、次のように書きます：

```elixir
cs.changes != %{}
```

あるいは、`Enum.empty?(cs.changes)` でも同じです。

また、ActiveRecord オブジェクトには `name_changed?` メソッドがあります。これは `name` 属性の値が変更されたかどうかを `true` または `false` で返します。

Ecto で同様のことを行うには、次のように書きます：

```elixir
Ecto.Changeset.changed?(cs, :name)
```

本稿で紹介した ActiveRecord オブジェクトのメソッド `name_was` や `changed?` や `name_changed?` は、Active Model の [Dirty](https://api.rubyonrails.org/v7.1/classes/ActiveModel/Dirty.html) クラスで定義されています。

----

ActiveRecord と Ecto を比較すると、前者の方が概念の数が少なくてシンプルです。しかし、その分、オブジェクトに詰め込まれる情報量が大きくなります。メモリ効率という観点からは Ecto の方が有利です。

とは言え、Ecto の「チェンジセット」という考え方は初級者にとってやや難しいかもしれません。チェンジセット構造体がスキーマ構造体を包み込むイメージを想像することをおすすめします。
