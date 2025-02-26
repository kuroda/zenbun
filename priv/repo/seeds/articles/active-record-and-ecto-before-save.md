---
title: "ActiveRecord と Ecto の比較①: before_save コールバック"
published: true
type: tech
emoji: 🫐
topics: ["Rails", "ActiveRecord", "Elixir", "Ecto"]
---

本稿は、ActiveRecord と Ecto を比較するシリーズの第 1 回です。

ActiveRecord は Ruby on Rails の一部を構成するライブラリです。Ecto は Elixir のライブラリです。いずれもデータベースを操作するために利用します。

今回は、ActiveRecord の特徴的なクラスメソッドである `before_save` について簡単に解説した後、同等のことを Ecto で実現するにはどうするのか、という話をします。

----

前提条件として、データベースに `users` テーブルがあり、これは `email` という名前の文字列型のカラムがあるとします。

次の Ruby コードをご覧ください。

```ruby
class User < ApplicationRecord
  before_save :downcase_email

  private
    def downcase_email
      self.email.downcase!
    end
end
```

`User` モデルクラスを定義しています。プライベートメソッド `downcase_email` が定義されていて、このメソッドを `before_save` クラスメソッドでコールバックとして指定しています。「コールバック」とは、ある処理の途中で呼び出されるメソッドのことです。`before_save` コールバックは、`users` テーブルに対するレコードの挿入または更新が行われる直前に呼び出されます。

使用例は次のようになります。

```ruby
u = User.new
u.assign_attributes(email: "ALICE@EXAMPLE.COM")
u.save
```

この結果、`users` テーブルに挿入されたレコードの `email` カラムの値は `"alice@example.com"` となります。

同等のことを Ecto で行うには、関数 [Ecto.Changeset.prepare_changes/2](https://hexdocs.pm/ecto/Ecto.Changeset.html#prepare_changes/2) を利用します。

次の Elixir コードをご覧ください。

```elixir
defmodule User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email])
    |> prepare_changes(&downcase_email/1)
  end

  defp downcase_email(changeset) do
    email = get_field(changeset, :email)
    put_change(changeset, :email, String.downcase(email))
  end
end
```

使用例は次のようになります。

```ruby
{:ok, u} =
  %User{}
  |> User.changeset(%{email: "ALICE@EXAMPLE.COM"})
  |> MyApp.Repo.insert()
```

さて、ソースコードを比較すると Elixir 版の方が Ruby 版よりもかなり長くなっています。総じて Ecto は ActiveRecord よりも明示的です。ActiveRecord はシステム起動時にデータベース管理システムにテーブル定義の情報を問い合わせることで、モデルクラスに `email` や `email=` などのメソッドを暗黙的に定義しますが、Ecto では関数 `schema/2` を用いて、スキーマ構造体が持つフィールドを列挙する必要があります。

他にも ActiveRecord と Ecto の間には大きな違いがあります。ActiveRecord では、モデルクラスのインスタンスが次の2つの情報を持ちます。

* データベースから取得したテーブルレコードの元データ
* そのテーブルレコードに対して加えたい変更

しかし、Ecto においては「スキーマ構造体」が前者を表現し、「チェンジセット構造体」が後者を表現します。

次に示す Elixir 版のソースコードの抜粋をご覧ください。

```elixir
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email])
    |> prepare_changes(&downcase_email/1)
  end
```

`User` モジュールの関数 `changeset/2` は、2 つの引数を取ります。第 1 引数は `User` スキーマ構造体、第 2 引数は `%{email: "ALICE@EXAMPLE.COM"}` のようなマップ（Ruby のハッシュに相当）です。この関数からの戻り値は、チェンジセット構造体です。

パイプ演算子 `|>` を使わずに 2 〜 3 行目を書き換えると `cast(user, attrs, [:email])` のようになります。ここでは、マップ `attrs` からキー `:email` とその値だけを抜き出して `user` に対して適用し、チェンジセットを作ります。Rails における Strong Parameters の役割の一部を関数 [cast/4](https://hexdocs.pm/ecto/Ecto.Changeset.html#cast/4) が担っています。

----

さて、ここからが本題です。

`Ecto.Changeset` モジュールの関数 [prepare_changes/2](https://hexdocs.pm/ecto/Ecto.Changeset.html#prepare_changes/2) は第 1 引数にチェンジセット構造体、第 2 引数に無名関数（匿名関数）を受け取って、チェンジセット構造体を返します。

引数部分の `&downcase_email/1` で使われている `&` は「キャプチャ演算子」と呼ばれ、後続の名前を持つ有名の関数を無名関数に変換します。スラッシュ記号（`/`）の右にある `1` は、関数のアリティ（引数の個数）を示します。

プライベート関数 `downcase_email/1` は次のように定義されています。

```elixir
defp downcase_email(changeset) do
  email = get_field(changeset, :email)
  put_change(changeset, :email, String.downcase(email))
end
```

この関数は引数にチェンジセット構造体を受け取って、チェンジセット構造体を返します。関数 [get_field/3](https://hexdocs.pm/ecto/Ecto.Changeset.html#get_field/3) はチェンジセットからフィールドの値を抜き出して返します。さきほどの使用例を実行したとすれば、変数 `email` には `"ALICE@EXAMPLE.COM"` がセットされます。

関数 [String.downcase/2](https://hexdocs.pm/elixir/String.html#downcase/2) は文字列を受け取って、そこに含まれるアルファベットをすべて小文字に変換して返します。

そして、関数 [put_change/3](https://hexdocs.pm/ecto/Ecto.Changeset.html#put_change/3) は、チェンジセット構造体に新たな変更点を登録します。ここでは、`:email` フィールドに `"alice@example.com"` という変更をセットします。

関数 `prepare_changes/2` によってチェンジセット構造体に登録された無名関数は、データベースに対して挿入、更新、または削除を行う場合に、操作の直前に実行されます。削除操作の前にも実行される点で ActiveRecord の `before_save` コールバックとは異なります。

----

もし、挿入と更新の場合だけ `:email` フィールドに変更を加えたいのであれば、次のように書けます。

```elixir
defp downcase_email(changeset) do
  if changeset.action in [:insert, :update] do
    email = get_field(changeset, :email)
    put_change(changeset, :email, String.downcase(email))
  else
    changeset
  end
end
```

`MyApp.Repo` モジュールの関数によりデータベース操作が行われるとき、チェンジセット構造体の `action` フィールドには、操作の種類を示すアトム（`:insert`、`:update`、`:delete`、など）がセットされていますので、その値によって処理を分岐できます。

しかし、削除の直前に `:email` フィールドに変更を加えたとしても、余分な更新処理が実行されるわけではないので無害です。ここまで書く必要はないでしょう。

----

以上の解説を読んで ActiveRecord の方が簡単でいいな、と思われた方もいらっしゃるでしょう。

実際のところ、ActiveRecord の方が入門のハードルが低い点は否めないです。

けれども、Web アプリケーションの開発が進んでソースコードが複雑になってくると、Ecto の明瞭さが効いてきます。[次回](https://zenn.dev/tkrd/articles/phoenix-context)はその辺りを深堀したいと思います。
