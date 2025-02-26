---
title: "Ecto: PostgreSQL の範囲型を扱う①"
published: true
type: tech
emoji: 🫐
topics: ["Ecto", "PostgreSQL"]
---

# はじめに

本稿は、「PostgreSQL の範囲型を扱う」シリーズの第 1 回です。

PostgreSQL の**範囲型** (range types)とは、整数、数値、日付、日時などの範囲を表すデータ型です。本稿で扱う日付範囲型は、「2025年1月1日から2025年1月3日まで」のような日付の範囲を表すことができます。

Ecto でPostgreSQL の範囲型を扱うには、Hex パッケージ [pg_ranges](https://hex.pm/packages/pg_ranges) を利用すると便利です。

この回では、Anemone という名前のサンプルアプリケーションのソースコードの骨格を作るところから始め、`pg_ranges` のインストール、データベーステーブルと構造体モジュールの定義と進み、最後に範囲型の値を持つレコードをデータベーステーブルに挿入するところまでをカバーします。

# 準備作業

## Phoenix installer のバージョンを確認

```
$ mix phx.new --version
Phoenix installer v1.7.19
```

本稿は Phoenix installer v1.7.19 で生成されたソースコードに基づきます。

## Anemone アプリを作る

```
$ mix phx.new anemone
$ cd anemone
```

`anemone` はサンプルアプリケーションの名前です。

## Hex ライブラリ `pg_ranges` を導入

```diff elixir:mix.exs (58-63)
        {:jason, "~> 1.2"},
        {:dns_cluster, "~> 0.1.1"},
-       {:bandit, "~> 1.5"}
+       {:bandit, "~> 1.5"},
+       {:pg_ranges, "~> 1.1"}
      ]
    end
```

```
$ mix deps.get
```

# データベーステーブルとスキーマの定義

## `community_events` テーブルのマイグレーションスクリプトを作る

```
$ mix phx.gen.schema Community.Event community_events
* creating lib/anemone/community/event.ex
* creating priv/repo/migrations/20250205131114_create_community_events.exs

Remember to update your repository by running migrations:

    $ mix ecto.migrate
```

```diff elixir:priv/repo/migrations/20250205131114_create_community_events.exs
  defmodule Anemone.Repo.Migrations.CreateCommunityEvents do
    use Ecto.Migration

    def change do
      create table(:community_events) do
+       add :name, :string
+       add :duration, :daterange

        timestamps(type: :utc_datetime)
      end
    end
  end
```

```
$ mix ecto.setup
The database for Anemone.Repo has been created

22:14:44.844 [info] == Running 20250205131114 Anemone.Repo.Migrations.CreateCommunityEvents.change/0 forward

22:14:44.846 [info] create table community_events

22:14:44.851 [info] == Migrated 20250205131114 in 0.0s
```

## 構造体モジュール `Anemone.Community.Event` の定義

```diff elixir:src/articles/anemone/lib/anemone/community/event.ex
  defmodule Anemone.Community.Event do
    use Ecto.Schema
    import Ecto.Changeset
+   alias PgRanges.DateRange

    schema "community_events" do
+     field :name, :string
+     field :duration, DateRange

      timestamps(type: :utc_datetime)
    end

    @doc false
    def changeset(event, attrs) do
      event
      |> cast(attrs, [])
      |> validate_required([])
    end
  end
```

# 日付範囲型のフィールド `duration` に値をセットする

## テストスクリプトを作る

```
$ mkdir -p test/anemone/community
```

```elixir:src/articles/anemone/test/anemone/community/event_test.exs
defmodule Anemone.Community.EventTest do
  use Anemone.DataCase
  alias PgRanges.DateRange
  alias Anemone.Community.Event

  describe "changeset/2" do
    test "convert starts_on and ends_on to a %DateRange{}" do
      {:ok, event} =
        %Event{}
        |> Event.changeset(%{
          name: "Test",
          starts_on: "2025-01-01",
          ends_on: "2025-01-03"
        })
        |> Repo.insert()

      e = Repo.get(Event, e.id)

      assert e.duration == %DateRange{
               lower: ~D[2025-01-01],
               lower_inclusive: true,
               upper: ~D[2025-01-04],
               upper_inclusive: false
             }
    end
  end
end
```

このテストは構造体 ` Anemone.Community.Event` に仮想フィールド `starts_on` と `ends_on` を付け加えるつもりで作っています。

17 行目で関数 `assert/1` を用いて、`e.duration` の値を確認しています。演算子 `==` の右辺には次のように書かれています。

```elixir
%DateRange{
  lower: ~D[2025-01-01],
  lower_inclusive: true,
  upper: ~D[2025-01-04],
  upper_inclusive: false
}
```

これは、`~D[2025-01-01]` を下限、`~D[2025-01-04]` を上限とする日付範囲を表す構造体です。`lower_inclusive` フィールドは範囲が下限を含むかどうかを、`upper_inclusive` フィールドは範囲が上限を含むかどうかを真偽値で表します。

実は、上記の構造体と次の構造体は意味的に同じです。

```elixir
%DateRange{
  lower: ~D[2025-01-01],
  lower_inclusive: true,
  upper: ~D[2025-01-03],
  upper_inclusive: true
}
```

第 2 の構造体をデータベースに保存し、改めてデータベースからレコードとして取得し直すと、第 1 の構造体が返ってきます。

## テストが失敗することを確認

```
$ mix test test/anemone/community/event_test.exs
Running ExUnit with seed: 708142, max_cases: 24



  1) test changeset/2 convert starts_on and ends_on to a %DateRange{} (Anemone.Community.EventTest)
     test/anemone/community/event_test.exs:7
     Assertion with == failed
     code:  assert event.duration == DateRange.new(~D"2025-01-01", ~D"2025-01-03")
     left:  nil
     right: %PgRanges.DateRange{lower: ~D[2025-01-01], lower_inclusive: true, upper: ~D[2025-01-03], upper_inclusive: true}
     stacktrace:
       test/anemone/community/event_test.exs:17: (test)


Finished in 0.04 seconds (0.00s async, 0.04s sync)
1 test, 1 failure
```

テストスクリプトの 17 行目で失敗しています。`event.duration` の値が構造体 ` Anemone.Community.Event` ではなく `nil` であるためです。

## テストが通るように `Event.changeset/2` を書き換える

```diff elixir:src/articles/anemone/lib/anemone/community/event.ex
  defmodule Anemone.Community.Event do
    use Ecto.Schema
    import Ecto.Changeset
    alias PgRanges.DateRange

    schema "community_events" do
      field :name, :string
      field :duration, DateRange
+     field :starts_on, :date, virtual: true
+     field :ends_on, :date, virtual: true

      timestamps(type: :utc_datetime)
    end

+   @fields [:name, :starts_on, :ends_on]

    @doc false
    def changeset(event, attrs) do
      event
-     |> cast(attrs, [])
-     |> validate_required([])
+     |> cast(attrs, @fields)
+     |> validate_required(@fields)
+     |> change_duration()
    end

+   defp change_duration(cs) do
+     starts_on = get_field(cs, :starts_on)
+     ends_on = get_field(cs, :ends_on)
+
+     if starts_on && ends_on do
+       if Date.after?(starts_on, ends_on) do
+         add_error(
+           cs,
+           :starts_on,
+           "must be the same as or earlier than the end date"
+         )
+       else
+         put_change(cs, :duration, %DateRange{
+           lower: starts_on,
+           lower_inclusive: true,
+           upper: ends_on,
+           upper_inclusive: true
+         })
+       end
+     else
+       cs
+     end
+   end
  end
```

プライベート関数 `change_duration/1` では、仮想フィールド `starts_on` と `ends_on` の値を調べ、それらが正しいもであれば、関数 [put_change/3](https://hexdocs.pm/ecto/Ecto.Changeset.html#put_change/3) を用いて、フィールド`duration` に `DateRange` 構造体をセットしています。

仮想フィールド `starts_on` と `ends_on` の値が正しくなければ、関数 [add_error/4](https://hexdocs.pm/ecto/Ecto.Changeset.html#add_error/4) を用いて、エラーを登録しています。

## テストが成功することを確認

```
$ mix test test/anemone/community/event_test.exs
Compiling 1 file (.ex)
Running ExUnit with seed: 3381, max_cases: 24

.
Finished in 0.02 seconds (0.00s async, 0.02s sync)
1 test, 0 failures
```

[次回](https://zenn.dev/tkrd/articles/ecto_pg_ranges-2)は、イベントの名前と開始日と終了日をブラウザ上に表示できるようにします。
