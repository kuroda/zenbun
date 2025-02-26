---
title: Tailwind CSS 後編
published: true
type: tech
emoji: 🥷
topics: ["elixir", "phoenix", "liveview", "youtube"]
---

# 動画

https://www.youtube.com/watch?v=gEVzBYTRBNs

[前回](https://zenn.dev/tkrd/articles/0cc6f70749e3466)の続きです。

# リストと配列

動画の冒頭で、リストと配列というプログラミング用語について話しました。

動画では両者を区別せずに次のように説明し、

* Elixir では「リスト」と呼ぶ。
* Python や Ruby では「配列」と呼ぶ

内部構造の違いと得手不得手があると述べるにとどめました。

Elixir の「リスト」は、一般に「連結リスト（linked list）」と呼ばれるデータ構造です。連結リストには次のような長所と短所があります：

* 【長所】要素の挿入・削除を素早く行える。
* 【短所】N番目の要素の探索に時間がかかる。

配列の長所と短所は、この裏返しです。

* 【長所】N番目の要素の探索を素早く行える
* 【短所】要素の挿入・削除に時間がかかる。

もっと詳しく知りたい方は、下記の資料を参照してください：

* 『アルゴリズム、データ構造の基本を学ぶ本』（鳥羽眞嘉、2022年、Zenn Book）の Chapter 08 「[配列と連結リスト](https://zenn.dev/masahiro_toba/books/436c018f5cd4e2/viewer/af0195)」
* [『Elixir実践ガイド (impress top gearシリーズ)』](https://www.amazon.co.jp/dp/4295010774/ref=nosim?tag=oiax-22)（黒田努、2021年、インプレス刊）の第 12 章「リスト」

# ライブコーディング①

前回の動画では、ブラウザの画面に表示されている円板をユーザーがクリックするとランダムに大きさと色が変わっていくところまでを作りました。

今回の動画では、まずユーザーがクリックしても 4 分の 1 の確率で色が変化しない、という課題に対応しました。

修正対象となるファイルは、`lib/dynamic_disc_web/live/demo_live.ex` です。

```diff elixir:lib/dynamic_disc_web/live/demo_live.ex (20-30)
    @background_colors ~w(
      bg-red-500
      bg-green-500
      bg-blue-500
      bg-cyan-500
    )

    def handle_event("change_state", _params, socket) do
-     bg_color = Enum.random(@background_colors)
+     bg_color =
+        Enum.random(@background_colors -- [socket.assigns.bg_color])

      socket =
        socket
        |> assign(:diameter, Enum.random(50..300))
        |> assign(:bg_color, bg_color)

      {:noreply, socket}
    end
```

前回の[解説記事](https://zenn.dev/tkrd/articles/0cc6f70749e3466)で書いたように、関数 `Enum.random/1` はリストからランダムに要素を 1 つ取り出します。

書き換える前は単純に 4 つの色から選び出していましたが、書き換え後は、4 つの色から現在使われている色を除外した 3 色から選び出しています。

4 つの色から現在使われている色を除外する処理を行っているのは、ここです：

```elixir
@background_colors -- [socket.assigns.bg_color]
```

演算子 `--` は左辺のリストと右辺のリストの差分を取ります。右辺はリストでなければならないので、次のように書くとエラーが発生します：

```elixir
@background_colors -- socket.assigns.bg_color
```

# ライブコーディング②

動画の後半では、円板のサイズと色が 1 秒かけて徐々に変化するようなエフェクトをかけました。

修正対象となるファイルは、`lib/dynamic_disc_web/live/demo_live.ex` です。

```diff elixir:lib/dynamic_disc_web/live/demo_live.ex (32-43)
    @class_tokens ~w(
      rounded-full
      cursor-pointer
+     translate-all
+     duration-1000
    )

    defp get_class(bg_color) do
      tokens = [bg_color | @class_tokens]
      Enum.join(tokens, " ")
    end
  end
```

`translate-all` は、**トランジション効果**を加えるための Tailwind CSS のクラスです。

要素の幅、高さ、文字色、背景色のような CSS プロパティの値が変更された時に、それをすぐに適用するのではなく、時間をかけて推移させるのがトランジション効果です。

さらにクラス `transition-1000` を加えるとトランジションにかかる時間が 1000 ミリ秒、つまり 1 秒になります。

詳しくは、Tailwind CSS 公式ドキュメントの下記の項を参照してください：

* [Transition Property](https://tailwindcss.com/docs/transition-property)
* [Transition Duratio](https://tailwindcss.com/docs/transition-duration)
