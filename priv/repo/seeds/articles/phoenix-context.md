---
title: "ActiveRecord と Ecto の比較②: コンテキスト"
published: true
type: tech
emoji: 🫐
topics: ["Rails", "ActiveRecord", "Elixir", "Phoenix", "Ecto"]
---

本稿は、ActiveRecord と Ecto を比較するシリーズの第 2 回です。

ActiveRecord は Ruby on Rails の一部を構成するライブラリです。Ecto は Elixir のライブラリです。いずれもデータベースを操作するために利用します。

今回は、Elixir/Phoenix の世界で使われる「コンテキスト」という概念について書きます。[前回](https://zenn.dev/tkrd/articles/active-record-and-ecto-before-save)の話の続きです。

----

前回の記事で使用した Elixir の `User` 構造体モジュールのソースコードを再掲します。

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

ActiveRecord の `before_save` コールバックを直接的に Ecto に翻訳しようとするとこうなりますけれども、実際の Web システム開発ではあまりこんな風には書きません。

私なら `User` 構造体を操作する関数群を集めたモジュールを別に作り、`downcase_email/1` のような処理はそちらに移します。例えば、次のように `MyApp.Account` モジュールを定義します。

```elixir
defmodule MyApp.Account do
  alias Account.User
  alias MyApp.Repo
  import Ecto.Changeset

  def create_user(attrs) do
    %User{}
    |> User.changeset(attrs)
    |> downcase_email()
    |> Repo.insert()
  end

  def update_user(user, attrs) do
    user
    |> User.changeset(attrs)
    |> downcase_email()
    |> Repo.update()
  end

  defp downcase_email(changeset) do
    email = get_field(changeset, :email)
    put_change(changeset, :email, String.downcase(email))
  end
end
```

そして、`User` 構造体は `MyApp.Account.User` 構造体に改名し、そのソースコードを次のように書き換えます。

```elixir
defmodule MyApp.Account.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    cast(user, attrs, [:email])
  end
end
```

`MyApp.Account` モジュールと `MyApp.Account.User` モジュールのパスは次の通りです：

* `my_app/lib/my_app/account/account.ex`
* `my_app/lib/my_app/account/account/user.ex`

使用例は次のようになります。

```ruby
{:ok, u} = MyApp.Account.create_user(%{email: "ALICE@EXAMPLE.COM"})
{:ok, u} = MyApp.Account.update_user(%{email: "BOB@example.com"})
```

----

Elixir/Phoenix の世界では `MyApp.Account` のようなモジュールを**コンテキスト**と呼びます。コンテキストには、Web システムの様々な機能（ビジネスロジック）を実現する関数群を集めます。そして、構造体モジュールには、フィールドの定義、外部から送られてきたパラメータのフィルタリング、バリデーションだけを残します。

コントローラから構造体モジュールの関数を呼ぶのは正しい作法ではありません。`MyApp.Account.User` モジュールの関数 `changeset/2` の定義の直前に `@doc false` というアノテーションが付加されています。これは、この関数はパブリックではあるけれども、コンテキストを経由せずに直接呼び出すべきではない、という意味になります。

こういった事情があるので、Elixir/Phoenix による Web システム開発において、`Ecto.Changeset` モジュールの関数 [prepare_changes/2](https://hexdocs.pm/ecto/Ecto.Changeset.html#prepare_changes/2) はあまり使われません。

Rails の ActiveRecord では、モデルクラスに多くの機能を集約します。Web システム開発の初期段階においては、その方が有利です。ディレクトリ構造が単純になり、ソースコードの個数が減るので。しかし、開発が進むにつれてモデルクラスの役割が肥大化し、管理しづらくなります。Elixir/Phoenix では、コンテキストと構造体モジュールを分離することにより、その問題を回避しています。

[次回](https://zenn.dev/tkrd/articles/active-record-and-ecto-validations)は「バリデーション」の観点から ActiveRecord と Ecto を比較する予定です。
