---
title: Elixir ホットコードスワッピング入門①
published: true
type: tech
emoji: ⚗️
topics: ["elixir", "eralang"]
---

# はじめに

Erlang/Elixir には、稼働中のプログラムのコードを更新する**ホットコードスワッピング**（hot code swapping）という機能があります。本稿ではこの機能を解説します。

本稿執筆にあたり使用した Erlang/Elixir のバージョンは次のとおりです:

* Erlang/OTP 27
* Elixir 1.17.3

# 準備作業: Mix プロジェクトを作る

本稿では本番環境で稼働中の Elixir プログラムをダウンタイムなしで更新できることを具体的なコードに基づいて確かめていきます。

適当なディレクトリで `mix new anemone --sup` コマンドを実行し、Anemone という名前のアプリのソースコードの骨格を生成します。スーバーバイザーの機能を使用するため `--sup` オプションを付けています。

`cd anemeno` コマンドで Anemone アプリのルートディレクトリに移動してください。

# Counter モジュールを GenServer として定義する

`lib/anemone` ディレクトリに新規ファイル `counter.ex` を作成し、次のコードを書き入れてください。

```elixir:lib/anemone/counter.ex (New)
defmodule Counter do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, 0, name: :counter)
  end

  @impl GenServer
  def init(count) do
    GenServer.cast(self(), :increment)

    {:ok, count}
  end

  @impl GenServer
  def handle_cast(:increment, count) do
    IO.puts("count[#{@vsn}]: #{count}")

    Process.sleep(1000)
    GenServer.cast(self(), :increment)

    {:noreply, count + 1}
  end
end
```

GenServer モジュール `Counter` を定義しています。GenServer についての解説は省略しますが、BEAM 内のプロセスに届くメッセージを処理するための関数群を持つモジュールだと考えてください。

まず、5 行目で `name` オプションに `:counter` を指定して [GenServer.start_link/3](https://hexdocs.pm/elixir/1.17.3/GenServer.html#start_link/3) を呼び出している点に着目してください。これにより、`Counter` サーバーをプロセス ID ではなく、アトム `:counter` で参照できるようになります。

次に、コールバック `handle_cast/2` の中身に着目してください。仮引数 `count` の値を画面出力した後に、1000 ミリ秒スリープし、自分自身に対して `:increment` メッセージを送り、`count` に 1 を加えて終わります。

`Counter` サーバーは 1 秒ごとに 1 ずつ増えていく整数の列をターミナルに出力し続けます。

# Counter サーバーをスーパーバイザーに登録する

`lib/anemone/application.ex` を次のように書き換えてください。

```diff elixir:lib/anemone/application.ex
  defmodule Anemone.Application do
    # See https://hexdocs.pm/elixir/Application.html
    # for more information on OTP Applications
    @moduledoc false

    use Application

    @impl true
    def start(_type, _args) do
      children = [
        # Starts a worker by calling: Anemone.Worker.start_link(arg)
        # {Anemone.Worker, arg}
+       Counter
      ]

      # See https://hexdocs.pm/elixir/Supervisor.html
      # for other strategies and supported options
      opts = [strategy: :one_for_one, name: Anemone.Supervisor]
      Supervisor.start_link(children, opts)
    end
  end
```

スーパーバイザーについての解説は省略します。このように書き換えることにより、Anemenne アプリの起動時に Counter サーバーが自動で起動するようになります。

# Anemone アプリを起動する

動作確認をしましょう。次のコマンドを実行してください。

```bash
mix run --no-halt
```

オプション `--no-halt` を付けないと、Anemene アプリはすぐに終了していしまいます。

ターミナル上には次のように出力されるはずです。

```
Compiling 1 file (.ex)
count: 0
count: 1
count: 2
count: 3
...
```

`Ctrl+C` を二度入力して、Anemone アプリを終了してください。

# リリースを作る

本番環境で Anemone アプリを動かすため、**リリース**を作ります。Elixir プログラムをコンパイルした時に作られる `.beam` ファイルなどの集合体をリリースと呼びます。

```bash
MIX_ENV=prod mix release
```

上記のコマンドを実行した結果、`_build/prod/rel` ディレクトリにさまざまなファイルが作られます。これがリリースです。

# 本番環境で Anemone アプリを起動する

次のコマンドを実行すると Anemone アプリが起動します。

```bash
_build/prod/rel/anemone/bin/anemone start
```

ターミナル上には次のように出力されるはずです。

```
count: 0
count: 1
count: 2
count: 3
...
```

このまま Anemone アプリを起動したままにして次に進みます。

# Counter モジュールを書き換える

`Counter` モジュールのソースコードを次のように書き換えてください。

```diff elixir:lib/anemone/counter.ex (16-24)
    def handle_cast(:increment, count) do
      IO.puts("count[#{@vsn}]: #{count}")

      Process.sleep(1000)
      GenServer.cast(self(), :increment)

-     {:noreply, count + 1}
+     {:noreply, count + 2}
    end
  end
```

この結果、`Counter` サーバーが出力する整数の列の間隔が 2 になります。

# リリースを更新する

次のコマンドを実行して、Anemone アプリのリリースを更新します。

```bash
MIX_ENV=prod mix release --overwrite
```

`ls -l _build/prod/rel/anemone/lib/anemone-0.1.0/ebin/` を実行して、`Elixir.Counter.beam` のタイムスタンプが最新のものになっていることを確認してください。

この時点では、Anemone アプリがターミナルに出力する整数列の間隔は 1 のままです。

# 起動中の Anemone アプリに接続する

次のコマンドを実行すると、起動中の Anemone アプリに IEx で接続できます。

```bash
_build/prod/rel/anemone/bin/anemone remote
```

# はじめてのホットコードスワッピング

IEx 上で次の 2 つの式を順に評価してください。

```
:code.purge(Counter)
:code.load_file(Counter)
```

この結果、Anemone アプリが稼働している仮想マシン BEAM に新しい `Counter` モジュールがロードされ、ターミナルに出力される整数列の間隔が 2 になります。どちらの式も `false` と評価されますが、問題ありません。

式 `:code.purge(Counter)` は現行の `Counter` モジュールを削除しますが、稼働中の `Counter` サーバーには影響を与えません。式 `:code.load_file(Counter)` を評価すると `Counter` サーバーの振る舞いが変化します。

なお、`:code.purge(Counter)` を評価せずに `:code.load_file(Counter)` だけを評価すると、`{:error, :not_purged}` というエラーメッセージが出力され、モジュールのロードに失敗します。

# モジュール属性 @vsn を導入する

ホットコードスワッピングを行う際に、`Counter` サーバーが保持する状態（`count`）の値を加工したい場合があります。

`Counter` モジュールのソースコードを次のように書き換えてください。

```diff elixir:lib/anemone/counter.ex (1-7)
  defmodule Counter do
    use GenServer
+   @vsn 1

    def start_link(_) do
      GenServer.start_link(__MODULE__, 0, name: :counter)
    end
```

モジュール属性 `@vsn` は、「version」の略です。ホットコードスワッピングの管理のために使われます。

関数 `handle_cast/2` の中身をいったん元に戻します。

```diff elixir:lib/anemone/counter.ex (17-25)
    def handle_cast(:increment, count) do
      IO.puts("count[#{@vsn}]: #{count}")

      Process.sleep(1000)
      GenServer.cast(self(), :increment)

-     {:noreply, count + 2}
+     {:noreply, count + 1}
    end
  end
```

リリースします。

```bash
MIX_ENV=prod mix release --overwrite
```

Anemone アプリを再起動してください。

```bash
_build/prod/rel/anemone/bin/anemone stop
_build/prod/rel/anemone/bin/anemone start
```

# Counter モジュールのバージョン 2 を作ってリリースする

続いて、`Counter` モジュールのソースコードを次のように書き換えてください。

```diff elixir:lib/anemone/counter.ex (1-7)
  defmodule Counter do
    use GenServer
-   @vsn 1
+   @vsn 2

    def start_link(_) do
      GenServer.start_link(__MODULE__, 0, name: :counter)
    end
```

```diff elixir:lib/anemone/counter.ex (17-25)
    def handle_cast(:increment, count) do
      IO.puts("count[#{@vsn}]: #{count}")

      Process.sleep(1000)
      GenServer.cast(self(), :increment)

-     {:noreply, count + 1}
+     {:noreply, count + 2}
    end
+
+   @impl GenServer
+   def code_change(1, count, _extra), do: {:ok, count + 1000}
  end
```

整数列の間隔が 2 となるように関数 `handle_cast/2` のコードを書き換え、コールバック `code_change/3` を実装しました。このコールバックの意味については後述します。

リリースしてください。

```bash
MIX_ENV=prod mix release --overwrite
```

# コールバック `GenServer.code_change/3` を利用したホットコードスワッピング

稼働中の Anemone アプリに IEx で接続します。

```bash
_build/prod/rel/anemone/bin/anemone remote
```

IEx 上で式 `:sys.suspend(:counter)` を評価すると Counter サーバーが一時停止します。ターミナルへの出力が止まったことを確認してください。筆者の手元では次の表示で止まっています。

```
...
count: 47
count: 48
count: 49
```

そして、IEx 上で以下の式を順に評価してください。

```
:code.purge(Counter)
:code.load_file(Counter)
:sys.change_code(:counter, Counter, 1, nil)
```

関数 [:sys.change_code/4](https://www.erlang.org/doc/apps/stdlib/sys.html#change_code/4) は、BEAM 上の停止中のプロセスに対してメッセージを送ります。メッセージを受けたプロセスは GenServer モジュールのコールバック `code_change/3` でメッセージを処理します。

`:sys.change_code/4` の第 3 引数に指定された `1` は、現在のプロセスと結びついている GenServer モジュールの `@vsn` 属性の値を意味します。第 4 引数の `nil` は、コールバック `code_change/3` の第 3 引数に渡されますが、今回は使用していません。

`Counter` モジュールのコールバック `code_change/3` のコードを再掲します。

```elixir
  def code_change(1, count, _extra), do: {:ok, count + 1000}
```

IEx 上で `:sys.change_code(:counter, Counter, 1, nil)` が評価されると、このコールバックが呼ばれ、`Counter` サーバーが保持する整数の値に 1000 が加えられます。しかし、`Counter` サーバーは停止中のため、ターミナルには何も出力されません。

# Counter サーバーの稼働を再開する

IEx 上で式 `:sys.resume(:counter)` を評価して Counter サーバーの稼働を再開してください。

すると、Counter サーバーが出力する数が 1001 増え、その後 2 ずつ増えていくようになります。

```
...
count: 47
count: 48
count: 49
count: 1050
count: 1052
count: 1054
```

# まとめ

本稿で解説したように、関数 `:code.load_file/1` を利用すると稼働中の Elixir アプリケーションの振る舞いを無停止で更新できます。これが「ホットコードスワッピング」です。

ホットコードスワッピング実施時に、GenServer プロセスが保持する状態を加工したい場合は、GenServer モジュールにコールバック `code_change/3` を実装し、GenServer プロセスを一時停止して、`:sys.change_code/4` 関数を呼び出します。

本稿では、整数を状態として持つ比較的単純な GenServer プロセスのホットコードスワッピングを扱いました。[次回](https://zenn.dev/tkrd/articles/elixir-hot-code-swapping-primer-2)は構造体を状態として持つ GenServer プロセスが稼働していて、その構造体の定義が変更された場合のホットコードスワッピングについては調べます。

# 参考資料

* [Elixir/Erlang Hot Swapping Code](https://kennyballou.com/blog/2016/12/elixir-hot-swapping/index.html)
* [はじめてな Elixir(30) プロセスのホットスワップをする](https://qiita.com/kikuyuta/items/94033d1da061109ea7e3#%E7%95%B0%E3%81%AA%E3%82%8B%E5%9E%8B%E3%81%AE%E7%8A%B6%E6%85%8B%E3%82%92%E6%8C%81%E3%81%A4%E3%83%97%E3%83%AD%E3%82%BB%E3%82%B9%E3%81%A7%E3%81%AE%E3%83%9B%E3%83%83%E3%83%88%E3%82%B9%E3%83%AF%E3%83%83%E3%83%97%E3%82%92%E8%A1%8C%E3%81%86)
* [Elixir - DistilleryによるHot Code Swapping](https://blog.engineer.adways.net/entry/2017/02/17/181049)
