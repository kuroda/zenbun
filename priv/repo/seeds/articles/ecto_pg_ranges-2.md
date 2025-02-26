---
title: "Ecto: PostgreSQL の範囲型を扱う②"
published: true
type: tech
emoji: 🫐
topics: ["Ecto", "PostgreSQL"]
---

# はじめに

本稿は、「PostgreSQL の範囲型を扱う」シリーズの第 2 回です。

[前回](https://zenn.dev/tkrd/articles/ecto_pg_ranges-1)は、サンプルアプリケーション Anemone を作成し、日付範囲型の `duration` カラムを持つ `community_events` テーブルにレコードを挿入するところまで進みました。

この回では、シードデータとして同テーブルに数件のレコードを挿入し、それらのデータを取得して、ブラウザの画面に表示します。

# シードデータ投入スクリプトの作成

## 関数 `Community.create_event!/3` の定義

```elixir:lib/anemone/community.ex (New)
defmodule Anemone.Community do
  alias Anemone.Repo
  alias Anemone.Community.Event
  alias PgRanges.DateRange

  def create_event!(name, starts_on, ends_on) do
    Repo.insert!(%Event{
      name: name,
      duration: %DateRange{
        lower: starts_on,
        lower_inclusive: true,
        upper: ends_on,
        upper_inclusive: true
      }
    })
  end
end
```

## `priv/repo/seeds.exs` の書き換え

`priv/repo/seeds.exs` の中身をすべて削除してから、次の内容を記入してください。

```elixir:priv/repo/seeds.exs
import Anemone.Community, only: [create_event!: 3]

create_event!("江戸ぶらり旅", ~D[2025-04-01], ~D[2025-04-01])
create_event!("FooBar 展示会", ~D[2025-05-01], ~D[2025-05-31])
create_event!("QUUX 祭", ~D[2025-05-10], ~D[2025-05-11])
create_event!("どきどきマーケット", ~D[2025-05-11], ~D[2025-05-17])
```

## シードデータの投入

```
$ mix ecto.reset

Compiling 2 files (.ex)
Generated anemone app
The database for Anemone.Repo has been dropped
The database for Anemone.Repo has been created

19:47:36.008 [info] == Running 20250205131114 Anemone.Repo.Migrations.CreateCommunityEvents.change/0 forward

19:47:36.010 [info] create table community_events

19:47:36.015 [info] == Migrated 20250205131114 in 0.0s
[debug] QUERY OK source="community_events" db=1.9ms queue=0.5ms idle=25.0ms
INSERT INTO "community_events" ("name","duration","inserted_at","updated_at") VALUES ($1,$2,$3,$4) RETURNING "id" ["江戸ぶらり旅", %PgRanges.DateRange{lower: ~D[2025-04-01], lower_inclusive: true, upper: ~D[2025-04-01], upper_inclusive: true}, ~U[2025-02-08 10:47:36Z], ~U[2025-02-08 10:47:36Z]]
↳ :elixir_compiler_3.__FILE__/1, at: priv/repo/seeds.exs:3
[debug] QUERY OK source="community_events" db=0.9ms queue=0.4ms idle=31.8ms
INSERT INTO "community_events" ("name","duration","inserted_at","updated_at") VALUES ($1,$2,$3,$4) RETURNING "id" ["FooBar 展示会", %PgRanges.DateRange{lower: ~D[2025-05-01], lower_inclusive: true, upper: ~D[2025-05-31], upper_inclusive: true}, ~U[2025-02-08 10:47:36Z], ~U[2025-02-08 10:47:36Z]]
↳ :elixir_compiler_3.__FILE__/1, at: priv/repo/seeds.exs:4
[debug] QUERY OK source="community_events" db=0.9ms queue=0.3ms idle=32.8ms
INSERT INTO "community_events" ("name","duration","inserted_at","updated_at") VALUES ($1,$2,$3,$4) RETURNING "id" ["QUUX 祭", %PgRanges.DateRange{lower: ~D[2025-05-10], lower_inclusive: true, upper: ~D[2025-05-11], upper_inclusive: true}, ~U[2025-02-08 10:47:36Z], ~U[2025-02-08 10:47:36Z]]
↳ :elixir_compiler_3.__FILE__/1, at: priv/repo/seeds.exs:5
[debug] QUERY OK source="community_events" db=0.9ms queue=0.3ms idle=33.6ms
INSERT INTO "community_events" ("name","duration","inserted_at","updated_at") VALUES ($1,$2,$3,$4) RETURNING "id" ["どきどきマーケット", %PgRanges.DateRange{lower: ~D[2025-05-11], lower_inclusive: true, upper: ~D[2025-05-17], upper_inclusive: true}, ~U[2025-02-08 10:47:36Z], ~U[2025-02-08 10:47:36Z]]
↳ :elixir_compiler_3.__FILE__/1, at: priv/repo/seeds.exs:6
```

# 空の「イベントのリスト」ページを作る

## 経路の変更

```diff elixir:lib/anemone_web/router.ex (17-21)
  scope "/", AnemoneWeb do
    pipe_through :browser

-   get "/", PageController, :home
+   get "/", EventController, :index
  end
```

## `PageController` モジュールの削除

`PageController` モジュールは使わないので、削除してください。

```
$ rm -rf lib/anemone_web/controllers/page_*
$ rm -rf test/anemone_web/controllers/page_controller_test.exs
```

## `EventController` モジュールの作成

```elixir:lib/anemone_web/controllers/event_controller.ex
defmodule AnemoneWeb.EventController do
  use AnemoneWeb, :controller

  def index(conn, _params) do
    render(conn, :index)
  end
end
```

## `EventHTML` モジュールの作成

```elixir:lib/anemone_web/controllers/event_html.ex
defmodule AnemoneWeb.EventHTML do
  use AnemoneWeb, :html

  embed_templates "event_html/*"
end
```

## `index.html` の設置

```html:lib/anemone_web/controllers/event_html/index.html.heex
<h1 class="text-2xl">イベントのリスト</h1>
```

![空の「イベントリスト」ページ](/images/articles/ecto_pg_ranges/anemone-1.png)

# 「イベントのリスト」ページの実装

## `EventController` モジュールの書き換え

```diff selixir:lib/anemone_web/controllers/event_controller.ex
  defmodule AnemoneWeb.EventController do
    use AnemoneWeb, :controller

    def index(conn, _params) do
-     render(conn, :index)
+     events = Community.list_events()
+
+     render(conn, :index, events: events)
    end
  end
```

## 関数 `Community.list_events/0` の実装

```diff elixir:lib/anemone/community.ex (1-12)
  defmodule Anemone.Community do
    alias Anemone.Repo
    alias Anemone.Community.Event
    alias PgRanges.DateRange
+
+   def list_events() do
+     from(e in Event, order_by: [asc: fragment("lower(?)", e.duration)])
+     |> Repo.all()
+     |> Enum.map(fn e ->
+       %{e | starts_on: e.duration.lower, ends_on: Date.add(e.duration.upper, -1)}
+     end)
+   end

    def create_event(name, starts_on, ends_on) do
```

`asc: fragment("lower(?)", e.duration)]` と書くことにより、イベントは開始日を基準に昇順でソートされます。
関数 [fragment/1](https://hexdocs.pm/ecto/Ecto.Query.API.html#fragment/1) は、クエリの中に埋め込むための生の SQL の断片を生成します。`lower` は、範囲の下限を返す PostgreSQL の関数です。

もし、終了日を基準に降順でソートしたいのなら、範囲の上限を返す PostgreSQL の関数 `upper` を使って次のように書くことになります。

```diff elixir:lib/anemone/community.ex (7-11)
    def list_events() do
-     from(e in Event, order_by: [asc: e.duration])
+     from(e in Event, order_by: [desc: fragment("upper(?)", e.duration)])
      |> Repo.all()
    end
```

10-12 行では、関数 `Enum.map/2` を用いて、`Event` 構造体の 2 つの仮想フィールド `starts_on` と `ends_on` に値をセットしています。`e.duration.upper` は終了日の翌日を示しているので、関数 `Date.add/2` を用いて 1 日前倒ししています。

## `index.html` の書き換え

```diff html:lib/anemone_web/controllers/event_html/index.html.heex
- <h1 class="text-2xl">イベントのリスト</h1>
+
+ <table class="border border-2 border-black mt-2">
+   <thead>
+     <tr>
+       <th class="p-2">名前</th>
+       <th class="p-2">開始日</th>
+       <th class="p-2">終了日</th>
+     </tr>
+   </thead>
+   <tbody>
+     <%= for event <- @events do %>
+       <tr>
+         <td class="p-2">{event.name}</td>
+         <td class="p-2">{event.starts_on}</td>
+         <td class="p-2">{event.ends_on}</td>
+       </tr>
+     <% end %>
+   </tbody>
+ </table>
```

![イベントのリスト](/images/articles/ecto_pg_ranges/anemone-2.png)

[次回](https://zenn.dev/tkrd/articles/ecto_pg_ranges-3)は、イベントの名前、開始日、終了日を編集するフォームを作ります。
