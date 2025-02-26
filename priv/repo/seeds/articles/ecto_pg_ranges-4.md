---
title: "Ecto: PostgreSQL の範囲型を扱う④"
published: true
type: tech
emoji: 🫐
topics: ["Ecto", "PostgreSQL"]
---

# はじめに

本稿は、「PostgreSQL の範囲型を扱う」シリーズの第 4 回（最終回）です。

[前回](https://zenn.dev/tkrd/articles/ecto_pg_ranges-3)は、イベントの編集フォームを表示し、イベントの名前、開始日、終了日を更新する機能を作りました。

この回では、条件を入力してイベントのリストを検索する（絞り込む）機能を作成します。

# 検索フォームの表示

## `Commnunity.SearchForm` モジュールの定義

```elixir:lib/anemone/community/search_form.ex (New)
defmodule Anemone.Community.SearchForm do
  use Ecto.Schema

  embedded_schema do
    field :from, :date
    field :until, :date
  end
end
```

## `Community` モジュールの書き換え

```diff elixir:lib/anemone/community.ex (42-54)
    def update_event(event, params) do
      event
      |> Event.changeset(params)
      |> Repo.update()
    end
+
+   def build_search_form(params) do
+     Ecto.Changeset.cast(%Anemone.Community.SearchForm{}, params, [
+       :from,
+       :until
+     ])
+   end
  end
```

## `EventController` モジュールの書き換え

```diff elixir:lib/anemone_web/controllers/event_controller.ex (5-10)
    def index(conn, params) do
+     search_form = Community.build_search_form(params)
      events = Community.list_events()

-     render(conn, :index, events: events)
+     render(conn, :index, events: events, search_form: search_form)
    end
```

## `EventHTML` モジュールの書き換え

```diff elixir:lib/anemone_web/controllers/event_html.ex
  defmodule AnemoneWeb.EventHTML do
    use AnemoneWeb, :html
+   import Phoenix.HTML.Form, only: [input_value: 2]

    embed_templates "event_html/*"
  end
```

## 関数コンポーネント `search_form` の定義

```html:lib/anemone_web/controllers/event_html/search_form.html.heex (New)
<.form :let={f} for={@search_form} action={~p(/)} method="get">
  <input type="date" name="from" value={input_value(f, :from)} />
  <input type="date" name="until" value={input_value(f, :until)} />
  <input type="submit" value="検索" class="btn btn-primary" />
  <a href={~p(/)} class="btn btn-neutral">クリア</a>
</.form>
```

## `index.html` の書き換え

```diff html:lib/anemone_web/controllers/event_html/index.html.heex (1-7)
  <h1 class="text-2xl">イベントのリスト</h1>
+
+ <div class="my-2">
+   <.search_form {assigns} />
+ </div>

  <table class="border border-2 border-black mt-2">
```

![イベントリストページに検索フォームを追加](/images/articles/ecto_pg_ranges/anemone-6.png)

# 検索機能の実装

## `Community` モジュールの書き換え

```diff elixir:lib/anemone/community.ex (8-23)
-   def list_events() do
-     from(e in Event, order_by: [asc: fragment("lower(?)", e.duration)])
-     |> Repo.all()
+   def list_events(search_form) do
+     range =
+       %Postgrex.Range{
+         lower: get_field(search_form, :from),
+         lower_inclusive: true,
+         upper: get_field(search_form, :until),
+         upper_inclusive: true
+       }
+
+     from(e in Event,
+       where: fragment("? && ?", e.duration, ^range),
+       order_by: [asc: fragment("lower(?)", e.duration)]
+     )
+     |> Repo.all()
      |> Enum.map(fn e -> populate_event(e) end)
    end
```

まず、`Postgrex.Range` 構造体のインスタンスを作って変数 `range` にセットしています。`lower` フィールドが `nil` の場合、その下限値が「マイナス無限大」であるという意味になります。同様に、`upper` フィールドが `nil` の場合、その下限値が「プラス無限大」であるという意味になります。`lower` フィールドと `upper` フィールドがともに `nil` である場合、すべての日付を含む日付範囲という意味になり、`where` オプションが指定されていないのと同じ結果をもたらします。

`from/2` の `where` オプションにおいて `fragment` 関数に `"? && ?"` というテンプレートが与えられています。ここで使われている `&&` は、左辺と右辺が重複する（共通点を持つ）かどうかを真偽値で返す PostgreSQL の演算子です。

`&&` の両辺に指定できるのは、範囲型の値または `Postgrex.Range` 構造体のインスタンスのみです。`PgRanges.DateRange` 構造体のインスタンスを指定するとエラーとなります。

## `EventController` モジュールの書き換え

```diff elixir:lib/anemone_web/controllers/event_controller.ex (5-10)
    def index(conn, params) do
      search_form = Community.build_search_form(params)
-     events = Community.list_events()
+     events = Community.list_events(search_form)

      render(conn, :index, events: events, search_form: search_form)
    end
```

これでイベントの検索ができるようになりました。検索フォームの 2 つの入力欄に「2025/05/01」と「2025/05/10」を入力して「検索」ボタンをクリックすると次のように 2 件のイベントがヒットします。

![検索結果](/images/articles/ecto_pg_ranges/anemone-7.png)

「Ecto: PostgreSQL の範囲型を扱う」シリーズはこれでおしまいです。
