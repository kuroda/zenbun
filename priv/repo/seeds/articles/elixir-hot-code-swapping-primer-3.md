---
title: Elixir ホットコードスワッピング入門➂
published: true
type: tech
emoji: ⚗️
topics: ["elixir", "eralang"]
---

# はじめに

本稿は[Elixir ホットコードスワッピング入門②](https://zenn.dev/tkrd/articles/elixir-hot-code-swapping-primer-2)の続きです。同じ構造体モジュールを参照する 2 個の GenServer プロセスが稼働しているときに、ホットコードスワッピングを行う方法について解説します。

「Elixir ホットコードスワッピング入門①〜②」で作成した Mix プロジェクト `Anemone` のソースコードを引き続き使用していきます。

# 関数 Script.run/1

これまでは、稼働中の `Anemone` アプリケーションに `_build/prod/rel/anemone/bin/anemone remote` コマンドで接続し、IEx 上で関数 `:sys.suspend/1` などを呼び出してホットコードスワッピングを実施していましたが、今回は呼び出す関数の数が多くなりますので、あらかじめ作成しておいたスクリプトを呼び出すことにします。

`lib/anemone` ディレクトリの下に新規ファイル `script.ex` を作成し、次のコードを書き入れてください。

```elixir:lib/anemone/script.ex
defmodule Script do
  def run(filename) do
    priv_dir = to_string(:code.priv_dir(:anemone))
    Code.require_file(filename, Path.join(priv_dir, "scripts"))
  end
end
```

関数 `Script/run/1` は、文字列 `filename` を引数として取り、`priv/scripts` ディレクトリの直下にある同名のファイルを読み込んで実行します。

# Inspector モジュールを GenServer として定義する

`lib/anemone` ディレクトリに新規ファイル `inspector.ex` を作成し、次のコードを書き入れてください。

```elixir:lib/anemone/inspector.ex (New)
defmodule Inspector do
  use GenServer
  @vsn 2

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: :inspector)
  end

  @impl GenServer
  def init(state) do
    GenServer.cast(self(), :next)
    {:ok, state}
  end

  @impl GenServer
  def handle_cast(:next, state) do
    IO.puts("[#{@vsn}] " <> inspect(%Account{}))

    Process.sleep(1000)
    GenServer.cast(self(), :next)

    {:noreply, state}
  end
end
```

関数 `handle_cast/2` に対して 1 秒おきに `:next` メッセージを送ることにより、式 `%Account{}` がどのような構造体を作るのかを調べています。ターミナル上には `[2] %Account{name: nil, score: 0, stage: 0}` という文字列が表示され続けます。

モジュール属性 `@vsn` の値は、`AppManager` モジュールと合わせて 2 とします。理由は後述します。

# Inspector サーバーをスーパーバイザーに登録する

`lib/anemone/application.ex` を次のように書き換えてください。

```diff elixir:lib/anemone/application.ex (10-14)
      children = [
        # Starts a worker by calling: Anemone.Worker.start_link(arg)
        # {Anemone.Worker, arg}
-       AccountManager
+       AccountManager,
+       Inspector
      ]
```

`Inspector` サーバーをスーパーバイザーに登録しています。

# Anemone アプリを起動する

次のコマンドを実行して Anemone アプリを起動してください。

```bash
mix run --no-halt
```

ターミナル上には次のように出力されるはずです。

```
alice: 0, bob: 0
[2] %Account{name: nil, score: 0, stage: 0}
alice: 1, bob: 1
[2] %Account{name: nil, score: 0, stage: 0}
alice: 2, bob: 2
[2] %Account{name: nil, score: 0, stage: 0}
alice: 3, bob: 3
[2] %Account{name: nil, score: 0, stage: 0}
...
```

`Ctrl+C` を二度入力して、Anemone アプリを終了してください。

# 本番環境で Anemone アプリを起動する

リリースを作ります。

```bash
MIX_ENV=prod mix release --overwrite
```

次のコマンドを実行すると Anemone アプリが起動します。

```bash
_build/prod/rel/anemone/bin/anemone start
```

このまま Anemone アプリを起動したままにして次に進みます。

# 構造体 Account の定義を変更する

構造体 `Account` に `active` フィールドを追加します。

```diff elixir:lib/anemone/account.ex
  defmodule Account do
-   defstruct name: nil, score: 0, stage: 0
+   defstruct name: nil, score: 0, stage: 0, active: true
  end
```

# AccountManager モジュールを書き換える

`AccountManager` モジュールのソースコードを次のように書き換えてください。

```diff elixir:lib/anemone/account_manager.ex (1-3)
  defmodule AccountManager do
    use GenServer
-   @vsn 2
+   @vsn 3
```

```diff elixir:lib/anemone/account_manager.ex (37-55)
    @impl GenServer
    def code_change(1, accounts, extra) do
      accounts =
        Enum.into(accounts, %{}, fn {k, v} ->
          {k, Map.put(v, :stage, @initial_stages[k])}
        end)

-     {:ok, accounts}
+     code_change(2, accounts, nil)
    end
+
+   def code_change(2, accounts, _extra) do
+     accounts =
+       Enum.into(accounts, %{}, fn {k, v} ->
+         {k, Map.put(v, :active, true)}
+       end)
+
+     {:ok, accounts}
+   end
  end
```

関数 `code_change/3` に節を追加し、現在稼働している `AccountManager` サーバーのバージョンが 1 であっても 2 であっても `Account` 構造体の定義変更に対応できるようにしました。

# Inspector モジュールを書き換える

`Inspector` モジュールのソースコードを次のように書き換えてください。

```diff elixir:lib/anemone/inspector.ex (1-3)
  defmodule Inspector do
    use GenServer
-   @vsn 2
+   @vsn 3
```

```diff elixir:lib/anemone/inspector.ex (20-31)
      GenServer.cast(self(), :next)

      {:noreply, state}
    end
+
+   @impl GenServer
+   def code_change(2, state, _extra) do
+     IO.puts("[code_change] " <> inspect(%Account{}))
+
+     {:ok, state}
+   end
  end
```

関数 `Inspector.code_change/3` では `%Account{}` の中身がどうなっているかを調べています。

# アップグレードスクリプトを作成する

ターミナルで `mkdir -p priv/scripts` を実行して `priv/scripts` ディレクトリを作成し、その下に新規ファイル `upgrade_3.exs` を作成して、次のコードを書き入れます。

```elixir:priv/scripts/upgrade_3.exs
server_name_and_module_pairs = [
  {:account_manager, AccountManager},
  {:inspector, Inspector}
]

for {server_name, mod} <- server_name_and_module_pairs do
  :sys.suspend(server_name)
end

:code.purge(Account)
:code.load_file(Account)

for {server_name, mod} <- server_name_and_module_pairs do
  :code.purge(mod)
  :code.load_file(mod)
  :sys.change_code(server_name, mod, 2, nil)
end

for {server_name, mod} <- server_name_and_module_pairs do
  :sys.resume(server_name)
end
```

このスクリプトは IEx 上でホットコードスワッピングのために行う一連の操作をまとめたものです。本稿ではこのスクリプトを**アップグレードスクリプト**と呼ぶことにします（一般的に広く使われる用語ではありません）。

このスクリプトが行っているのは、以下の一連の処理です。

* `AccountManager` サーバーと `Inspector` サーバーの停止
* `Account` モジュールの更新
* `AccountManager` モジュールと `Inspector` モジュールの更新
* `AccountManager` サーバーと `Inspector` サーバーの稼働再開

16 行目をご覧ください。

```elixir
  :sys.change_code(server_name, mod, 2, nil)
```

この 2 は、現在の（古い）バージョン番号を示します。`Inspector` モジュールのバージョン番号（`@vsn`）を 2 としたのは、この値を `AccountManager` モジュールと揃えるためです。

# アップグレードスクリプトを実行する

次のコマンドを実行して、Anemone アプリのリリースを更新します。

```bash
MIX_ENV=prod mix release --overwrite
```

起動中の Anemone アプリに IEx で接続します。

```bash
_build/prod/rel/anemone/bin/anemone remote
```

IEx 上で次の式を評価すると、アップグレードスクリプトが実行されます。

```elixir
Script.run("upgrade_3.exs")
```

Anemone アプリを起動したターミナルには次のように出力されます。

```
[code_change] %Account{name: nil, score: 0, stage: 0, active: true}
alice: 34, bob: 68
[3] %Account{name: nil, score: 0, stage: 0, active: true}
```

# アップグレードスクリプトの見直し

アップグレードスクリプト `priv/scripts/upgrade_3.exs` の 10-11 行をご覧ください。

```elixir
:code.purge(Account)
:code.load_file(Account)
```

`AccountManager` モジュールと `Inspector` モジュールを更新する前に、`Account` モジュールを更新しています。

この 2 行をコメントアウトしたアップグレードスクリプトを利用してここまで本稿でやってきたことを初めからやり直すと、Anemone アプリを起動したターミナルには次のように出力されます。

```
[code_change] %{name: nil, score: 0, stage: 0, __struct__: Account, active: true}
alice: 34, bob: 68
[3] %{name: nil, score: 0, stage: 0, __struct__: Account, active: true}
```

コメントアウトの前後で `[code_change]` の右側に出力されている文字列が次のように変化しています。

* `%Account{name: nil, score: 0, stage: 0, active: true}`
* `%{name: nil, score: 0, stage: 0, __struct__: Account, active: true}`

これは私にとって予想外の結果でした。後者のように表示されるということは、式 `%Account{}` によって作られる値が `Account` 構造体のインスタンスとして正しくないことを意味します。しかし、このマップには `:active` というキーが存在するので、新しい `Account` モジュールによってインスタンスが作られています。しかし、関数 `inspect/1` は、それが正しい `Account` 構造体のインスタンスではないと判定しているのです。

私はこの結果が生じた理由は解明できませんでした。とにかく、このようなことが起こりうるので、`AccountManager` モジュールと `Inspector` モジュールを更新するだけでは十分ではなく、それらが参照している `Account` モジュールも明示的に更新する必要があります。

# まとめ

本稿では複数の GenServer プロセスのモジュールが構造体モジュールを参照しているときに、どのようにホットコードスワッピングを行うべきかを調査しました。

完全なホットコードスワッピングを行うには GenServer プロセスのモジュールを更新するだけでは不十分で、構造体モジュールも明示的に更新すべきことがわかりました。

また、自作の関数 `Script.run/1` を用いて、`priv/scripts` ディレクトリに置かれたアップグレードスクリプトを IEx から呼び出すというテクニックを紹介しました。このテクニックは `mix release` の[ドキュメント](https://hexdocs.pm/mix/Mix.Tasks.Release.html)に書かれていないので、知らない人が多いかと思います。

「Elixir ホットコードスワッピング入門」と題したシリーズは、今回で終わりです。Phoenix アプリケーション、特に Phoenix LiveView を用いた Web アプリケーションにおけるホットコードスワッピングの利用に関しては稿を改めます。
