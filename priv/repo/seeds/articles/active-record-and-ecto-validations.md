---
title: "ActiveRecord と Ecto の比較③: バリデーション"
published: true
type: tech
emoji: 🫐
topics: ["Rails", "ActiveRecord", "Elixir", "Phoenix", "Ecto"]
---

本稿は、ActiveRecord と Ecto を比較するシリーズの第 3 回です。

ActiveRecord は Ruby on Rails の一部を構成するライブラリです。Ecto は Elixir のライブラリです。いずれもデータベースを操作するために利用します。

今回は、バリデーションに関して ActiveRecord と Ecto を比較します。[前回](https://zenn.dev/tkrd/articles/phoenix-context)の話の続きです。

----

ActiveRecord と Ecto の文脈で「バリデーション（validation）」とは、ユーザーが入力した値が正しいかどうかを検証することです。例えば、入力必須のフィールドが空だった場合やメールアドレスに `@` 記号が含まれていない場合に、バリデーションが失敗します。

[前々回の記事](https://zenn.dev/tkrd/articles/active-record-and-ecto-before-save)で使用した Rails の `User` クラスのコードを再掲します。

```ruby
class User < ApplicationRecord
  before_save :downcase_email

  private
    def downcase_email
      self.email.downcase!
    end
end
```

また、前回の記事で使用した Elixir の `MyApp.Account.User` 構造体モジュールのソースコードを再掲します。

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

これらに対して、`email` フィールドが空でないことを確認するバリデーションコードを追加しましょう。

まず、ActiveRecord 版はこうなります。

```ruby
class User < ApplicationRecord
  validates_presence_of :email
  before_save :downcase_email

  private
    def downcase_email
      self.email.downcase!
    end
end
```

2 行目に `validates_presence_of :email` を追加しました。

Ecto 版はこうなります。

```elixir
defmodule Account.User do
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
    |> validate_required([:email])
  end
end
```

関数 `changeset/2` の本体を

```elixir
    cast(user, attrs, [:email])
```

から次のように変更しました。

```elixir
    user
    |> cast(attrs, [:email])
    |> validate_required([:email])
```

パイプ演算子に慣れていないとわかりにくいですが、変更後のコードは次のように書き下せます。

```elixir
    cs = cast(user, attrs, [:email])
    validate_required(cs, [:email])
```

呼び出すメソッド／関数の名前が異なりますが、ActiveRecord 版も Ecto 版もバリデーションのために追加されたコード量はほぼ同じです。

しかし、両者の間には、根本的な違いがあります。

----

ActiveRecord 版ではクラスメソッド [validates_presence_of](https://api.rubyonrails.org/classes/ActiveModel/Validations/HelperMethods.html#method-i-validates_presence_of) を利用して、クラスにバリデーションコードを登録しています。

ここでは、一種の**メタプログラミング**（metaprogramming）が行われています。クラスメソッド `validates_presence_of` を呼び出すことにより、`User` クラスの `valid?` メソッドや `save` メソッドの振る舞いを変化させています。

Ecto 版では関数 [validate_required/3](https://hexdocs.pm/ecto/Ecto.Changeset.html#validate_required/3) を関数 `changeset/2` の中で呼び出しています。ここではメタプログラミングは行われていません。Ecto 版の方が ActiveRecord 版よりも明示的です。

----

続いて、条件付きバリデーションについて、ActiveRecord と Ecto を比較します。

`users` テーブルに真偽値型のカラム `provisional` を追加し、この値が `true` のときは `email` フィールドに関するバリデーションをスキップするという仕様を追加しましょう。

まず、ActiveRecord 版です。

```ruby
class User < ApplicationRecord
  validates_presence_of :email, unless: :provisional
  before_save :downcase_email

  private
    def downcase_email
      self.email.downcase!
    end
end
```

クラスメソッド `validates_presence_of` の `unless` オプションに `:provisional` を指定することで、`provisional` フィールドの値が `false` の場合だけバリデーションを実行するように設定しました。

他方、Ecto 版はこうなります。

```elixir
defmodule Account.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :provisional, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    cs = cast(user, attrs, [:email, :provisional])

    if get_field(cs, :provisional) do
      cs
    else
      validate_required(cs, [:email])
    end
  end
end
```

まず、7 行目で `provisional` フィールドの型と初期値を宣言しています。そして、関数 `changeset/2` の中で条件分岐によりバリデーション実施の有無を制御しています。

`Ecto.Changeset` モジュールの関数 [get_field](https://hexdocs.pm/ecto/Ecto.Changeset.html#get_field/3) は、第 1 引数にチェンジセット構造体、第 2 引数にフィールド名を表すアトムを指定し（省略可能な第 3 引数は、デフォルト値）、そのフィールドの値を返します。

`provisional` フィールドの値が `true` なら、チェンジセット構造体 `cs` をそのまま返しています。つまり、バリデーションをスキップしています。

一般に、Ecto を採用すると ActiveRecord よりもバリデーションコードは長くなります。良く言えば明示的、悪く言えば冗長です。

私は、ソフトウェアが複雑になればなるほど明示的なソースコードの価値が高くなると考えています。ActiveRecord のモデルクラス定義の冒頭に `if` オプションや `uneless` オプションが付いた `validates_` で始まるクラスメソッド呼び出しが数多く並ぶとソースコードの意味を把握するのが難しくなります。

[次回](https://zenn.dev/tkrd/articles/active-record-and-ecto-tracking-changes)は、変更内容の追跡という観点から ActiveRecord と Ecto を比較します。
