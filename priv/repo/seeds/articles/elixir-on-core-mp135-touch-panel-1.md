---
title: Elixir で M5Stack CoreMP135 のタッチパネルから入力を得る①
published: true
type: tech
emoji: 🫐
topics: ["elixir", "m5stack", "framebuffer"]
---

# 本稿について

本稿ではプログラミング言語 Elixir を用いて小型 Linux PC である M5Stack CoreMP135（以下、「CoreMP135」と呼ぶ）のタッチパネルから入力を得る方法について解説します。

拙稿 [Elixir を M5Stack CoreMP135 上で動かす](https://zenn.dev/tkrd/articles/elixir-on-m5stack-core-mp135) の内容に沿って Elixir を CoreMP135 にインストールしてあることが本稿の前提条件です。

# 謝辞

本稿の執筆に当たっては、e.mattsan さんのブログ記事 [Raspberry Pi 用タッチスクリーンを Elixir で利用する](https://blog.emattsan.org/entry/2021/05/24/175500) を大いに参考にしました。深く感謝いたします。

# Mix プロジェクト Magosteen を作る

適当なディレクトリで `mix new mangosteen --sup` コマンドを実行し、Mangosteen という名前の Mix プロジェクトの骨格を生成します。「Mangosteen」には特に意味はありません。スーバーバイザーの機能を使用するため `--sup` オプションを付けています。

`cd mangosteen` コマンドで Mangosteen アプリのルートディレクトリに移動してください。

# Hex パッケージ `input_event` の導入

Linux の**デバイスファイル**（device files）からイベントを取得するため、Hex パッケージ [input_event](https://hex.pm/packages/input_event) を導入します。

:::details デバイスファイル
Linux のデバイスファイルは、ハードウェア（デバイス）と入出力を行うための特殊なファイルです。
:::

`mix.exs` を次のように書き換えてください。

```diff elixir:mix.exs (23-28)
    defp deps do
      [
-       # {:dep_from_hexpm, "~> 0.3.0"},
-       # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
+       {:input_event, "~> 1.4.2"}
      ]
    end
  end
```

`mix deps.get` コマンドを実行し、Hex パッケージ `input_event` をインストールしてください。

# `TouchPanelWatcher` モジュールを GenServer として定義する

`lib/mangosteen` ディレクトリに新規ファイル `touch_panel_watcher.ex` を作成し、次のコードを書き入れてください。

```elixir:lib/mangosteen/touch_panel_watcher.ex (New)
defmodule TouchPanelWatcher do
  use GenServer
  require Logger

  @device_path "/dev/input/event0"

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil)
  end

  def init(_) do
    {:ok, _pid} = InputEvent.start_link(path: @device_path)
    {:ok, %{touching: false, x: nil, y: nil}}
  end

  def handle_info({:input_event, _path, events}, state) do
    state =
      events
      |> Enum.reduce(state, fn
        {:ev_abs, :abs_x, x}, acc -> %{acc | x: x}
        {:ev_abs, :abs_y, y}, acc -> %{acc | y: y}
        {:ev_key, :btn_touch, 0}, acc -> %{acc | touching: false}
        {:ev_key, :btn_touch, 1}, acc -> %{acc | touching: true}
        _, acc -> acc
      end)

    Logger.debug(state)

    {:noreply, state}
  end
end
```

GenServer モジュール `TouchPanelWatcher` を定義しています。ソースコードの解説は後回しにします。

# TouchPanelWatcher サーバーをスーパーバイザーに登録する

`lib/mangosteen/application.ex` を次のように書き換えてください。

```diff elixir:lib/mangosteen/application.ex
  defmodule Mangosteen.Application do
    # See https://hexdocs.pm/elixir/Application.html
    # for more information on OTP Applications
    @moduledoc false

    use Application

    @impl true
    def start(_type, _args) do
      children = [
        # Starts a worker by calling: Mangosteen.Worker.start_link(arg)
        # {Mangosteen.Worker, arg}
+       TouchPanelWatcher
      ]

      # See https://hexdocs.pm/elixir/Supervisor.html
      # for other strategies and supported options
      opts = [strategy: :one_for_one, name: Mangosteen.Supervisor]
      Supervisor.start_link(children, opts)
    end
  end
```

スーパーバイザーについての解説は省略します。このように書き換えることにより、Mangosteen アプリの起動時に TouchPanelWatcher サーバーが自動で起動するようになります。

# Mangosteen アプリを起動する

動作確認をしましょう。次のコマンドを実行してください。

```bash
mix run --no-halt
```

オプション `--no-halt` を付けないと Mangosteen アプリはすぐに終了していしまいます。

ターミナル上には次のように出力されるはずです。

```
Compiling 3 files (.ex)
Generated mangosteen app
```

CoreMP135 のタッチパネルを指で触って動かしてみて、次のように出力されれば成功です。

```
11:55:42.811 [debug] [y: 140, x: 97, touching: true]

11:55:42.924 [debug] [y: 140, x: 97, touching: false]

11:55:43.214 [debug] [y: 153, x: 68, touching: true]

11:55:43.250 [debug] [y: 153, x: 68, touching: false]
```

以上の出力は、タッチパネル上の座標 `(97, 140)` と `(68, 153)` がタップされたことを表します。

`Ctrl+C` を二度入力して、Mangosteen アプリを終了してください。

# ソースコードの解説

`TouchPanelWatcher` モジュールのソースコードについて解説します。

11-14 行をご覧ください。

```elixir
  def init(_) do
    {:ok, _pid} = InputEvent.start_link(path: @device_path)
    {:ok, %{touching: false, x: nil, y: nil}}
  end
```

TouchPanelWatcher サーバーの初期化をしています。関数 [InputEvent.start_link/1](https://hexdocs.pm/input_event/InputEvent.html#start_link/1) は、指定された入力デバイスからのイベントを報告する GenServer を起動します。イベントの報告はこの関数を呼び出したプロセスに届きます。

TouchPanelWatcher サーバーの初期状態は `%{touching: false, x: nil, y: nil}` です。

17-24 行をご覧ください。

```elixir
    state =
      Enum.reduce(events, state, fn
        {:ev_abs, :abs_x, x}, acc -> %{acc | x: x}
        {:ev_abs, :abs_y, y}, acc -> %{acc | y: y}
        {:ev_key, :btn_touch, 0}, acc -> %{acc | touching: false}
        {:ev_key, :btn_touch, 1}, acc -> %{acc | touching: true}
        _, acc -> acc
      end)
```

関数 [Enum.reduce/2](https://hexdocs.pm/elixir/Enum.html#reduce/2) を利用して TouchPanelWatcher サーバーの状態がセットされた変数 `state` を変換しています。

タッチパネルが接触開始を検知すると、関数 `TouchPanelWatcher.handle_info/2` が呼び出され、変数 `events` には次のようなタプルのリストがセットされます。

```elixir
[
  {:ev_abs, :abs_mt_tracking_id, 1},
  {:ev_abs, :abs_mt_position_x, 97},
  {:ev_abs, :abs_mt_position_y, 140},
  {:ev_key, :btn_touch, 1},
  {:ev_abs, :abs_x, 97},
  {:ev_abs, :abs_y, 140}
]
```

17-25 行のコードでこのリストを処理すると、変数 `state` には `%{touching: true, x: 97, y: 140}` がセットされます。

# まとめ

本稿で解説したように、Hex パッケージ `input_event` を利用すると割と簡単に CoreMP135 のタッチパネルから入力を得ることが可能です。

次回（未完成）は、本稿執筆で得た知識を利用して、液晶ディスプレイ上に描かれたボタンを「押す」ような UI を備えたアプリケーションを作ってみる予定です。

# 余談

Hex パッケージ `input_event` を見つけるまでの間、[CoreMP135でタッチパネルにタッチした結果を取得する](https://qiita.com/nnn112358/items/799062788810c26857d7) を参考にしてデバイスファイル `/dev/input/event0` を関数 `File.read/1` で読み出そうとしましたが、うまく行きませんでした。

# 参考文献

* [Raspberry Pi 用タッチスクリーンを Elixir で利用する](https://blog.emattsan.org/entry/2021/05/24/175500) -- e.mattsan
* [CoreMP135でタッチパネルにタッチした結果を取得する](https://qiita.com/nnn112358/items/799062788810c26857d7) -- @nnn112358(nnn)
