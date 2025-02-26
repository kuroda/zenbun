---
title: "Ecto: PostgreSQL の範囲型を扱う③"
published: true
type: tech
emoji: 🫐
topics: ["Ecto", "PostgreSQL"]
---

# はじめに

本稿は、「PostgreSQL の範囲型を扱う」シリーズの第 3 回です。

[前回](https://zenn.dev/tkrd/articles/ecto_pg_ranges-2)は、ブラウザの画面にイベントのリストを表示するところまで進みました。

この回では、イベントの編集フォームを作ります。

# イベントの編集ページを作る

## daisyUI の導入

```
cd assets
npm i daisyui@4.12.23
cd ..
```

```diff assets/tailwind.config.js (21-23)
    plugins: [
+     require("daisyui"),
      require("@tailwindcss/forms"),
```

## 経路の変更

```diff elixir:lib/anemone_web/router.ex (17-21)
  scope "/", AnemoneWeb do
    pipe_through :browser

    get "/", EventController, :index
+   get "/events/:id/edit", EventController, :edit
  end
```

## `index.html` の書き換え

```diff html:lib/anemone_web/controllers/event_html/index.html.heex
  <h1 class="text-2xl">イベントのリスト</h1>

  <table class="border border-2 border-black mt-2">
    <thead>
      <tr>
        <th class="p-2">名前</th>
        <th class="p-2">開始日</th>
        <th class="p-2">終了日</th>
+       <th class="p-2"></th>
      </tr>
    </thead>
    <tbody>
      <%= for event <- @events do %>
        <tr>
          <td class="p-2">{event.name}</td>
          <td class="p-2">{event.starts_on}</td>
          <td class="p-2">{event.ends_on}</td>
+         <td class="p-2">
+           <.link href={~p(/events/#{event}/edit)} class="underline">
+             編集
+           </.link>
+         </td>
        </tr>
      <% end %>
    </tbody>
  </table>
```

![「イベントリスト」ページに編集リンクを設置](/images/articles/ecto_pg_ranges/anemone-3.png)

## `EventController` モジュールの書き換え

```diff elixir:lib/anemone_web/controllers/event_controller.ex
  defmodule AnemoneWeb.EventController do
    use AnemoneWeb, :controller
    alias Anemone.Community

    def index(conn, _params) do
      events = Community.list_events()

      render(conn, :index, events: events)
    end
+
+   def edit(conn, %{"id" => id}) do
+     event = Community.get_event(id)
+     changeset = Community.change_event(event)
+
+     render(conn, :edit, event: event, changeset: changeset)
+   end
  end
```

## 関数 `Community.get_event/1` と `Community.change_event/1` の実装

```diff elixir:lib/anemone/community.ex (7-30)
    def list_events() do
      from(e in Event, order_by: [asc: fragment("lower(?)", e.duration)])
      |> Repo.all()
-     |> Enum.map(fn e ->
-       %{e | starts_on: e.duration.lower, ends_on: Date.add(e.duration.upper, -1)}
-     end)
+     |> Enum.map(fn e -> populate_event(e) end)
    end
+
+   def get_event(id) do
+     e = Repo.get(Event, id)
+     populate_event(e)
+   end
+
+   defp populate_event(e) do
+     %{
+       e
+       | starts_on: e.duration.lower,
+         ends_on: Date.add(e.duration.upper, -1)
+     }
+   end
+
+   def change_event(event) do
+     Ecto.Changeset.cast(event, %{}, [])
+   end

    def create_event!(name, starts_on, ends_on) do
```

## `edit.html` の設置

```html:lib/anemone_web/controllers/event_html/edit.html.heex
<h1 class="text-2xl">イベントの編集</h1>

<.form :let={f} for={@changeset} action={~p(/events/#{@event})}>
  <.input field={f[:name]} label="名前" />
  <.input field={f[:starts_on]} type="date" label="開始日" />
  <.input field={f[:ends_on]} type="date" label="終了日" />
  <div class="flex justify-end mt-4">
    <input type="submit" value="更新" class="btn btn-primary" />
  </div>
</.form>
```

## `core_components.ex` の書き換え

フォームのビジュアルデザインを整えるため、`AnemoneWeb.CoreComponents` モジュールの関数 `input/1` を書き換えます。

```diff elixir:lib/anemone_web/components/core_components.ex (444-463)
    def input(assigns) do
      ~H"""
-     <div>
+     <div class="mt-4">
        <.label for={@id}>{@label}</.label>
        <input
          type={@type}
          name={@name}
          id={@id}
          value={Phoenix.HTML.Form.normalize_value(@type, @value)}
          class={[
            "mt-2 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6",
-           @errors == [] && "border-zinc-300 focus:border-zinc-400",
+           @errors == [] && "border-zinc-400 focus:border-zinc-600",
            @errors != [] && "border-rose-400 focus:border-rose-400"
          ]}
          {@rest}
        />
        <.error :for={msg <- @errors}>{msg}</.error>
      </div>
      """
    end
```

![イベントの編集ページ](/images/articles/ecto_pg_ranges/anemone-3.png)

# イベントの更新

## 経路の変更

```diff elixir:lib/anemone_web/router.ex (17-21)
  scope "/", AnemoneWeb do
    pipe_through :browser

    get "/", EventController, :index
    get "/events/:id/edit", EventController, :edit
+   put "/events/:id", EventController, :update
  end
```

## `EventController` モジュールの書き換え

```diff elixir:lib/anemone_web/controllers/event_controller.ex (11-29)
    def edit(conn, %{"id" => id}) do
      event = Community.get_event(id)
      changeset = Community.change_event(event)

      render(conn, :edit, event: event, changeset: changeset)
    end
+
+   def update(conn, %{"id" => id, "event" => event_params}) do
+     event = Community.get_event(id)
+
+     case Community.update_event(event, event_params) do
+       {:ok, _event} ->
+         redirect(conn, to: ~p(/))
+
+       {:error, changeset} ->
+         render(conn, :edit, event: event, changeset: changeset)
+     end
+   end
  end
```

## 関数 `Community.update_event/2` の実装

```diff elixir:lib/anemone/community.ex (30-47)
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
+
+   def update_event(event, params) do
+     event
+     |> Event.changeset(params)
+     |> Repo.update()
+   end
  end
```

これでイベントの更新ができるようになりました。開始日の入力欄に終了日よりも後の日付を入力して「更新」ボタンをクリックすると次のようにエラーメッセージが表示されます。

![イベントの編集ページ](/images/articles/ecto_pg_ranges/anemone-5.png)

次回は、条件を入力してイベントのリストを絞り込む機能を作成します。
