---
title: Elixir ホットコードスワッピング入門②
published: true
type: tech
emoji: ⚗️
topics: ["elixir", "eralang"]
---

# はじめに

本稿は[Elixir ホットコードスワッピング入門①](https://zenn.dev/tkrd/articles/elixir-hot-code-swapping-primer-1)の続きです。構造体を状態として持つ GenServer プロセスが稼働していて、その構造体の定義が変更された場合のホットコードスワッピングについて解説します。

「Elixir ホットコードスワッピング入門①」で作成した Mix プロジェクト `Anemone` のソースコードを引き続き使用していきます。

# 構造体 Account を定義する

`lib/anemone` ディレクトリに新規ファイル `account.ex` を作成し、次のコードを書き入れてください。

```elixir:lib/anemone/account.ex (New)
defmodule Account do
  defstruct name: nil, score: 0
end
```

`name` および `score` という 2 つのフィールドを持つ構造体 `Account` を定義しています。

# AccountManager モジュールを GenServer として定義する

`lib/anemone` ディレクトリに新規ファイル `account_manager.ex` を作成し、次のコードを書き入れてください。

```elixir:lib/anemone/account_manager.ex (New)
defmodule AccountManager do
  use GenServer
  @vsn 1

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: :account_manager)
  end

  @impl GenServer
  def init(accounts) do
    GenServer.cast(self(), :increment)

    accounts =
      accounts
      |> Map.put("alice", %Account{name: "Alice"})
      |> Map.put("bob", %Account{name: "Bob"})

    {:ok, accounts}
  end

  @impl GenServer
  def handle_cast(:increment, accounts) do
    IO.puts("alice: #{accounts["alice"].score}, bob: #{accounts["bob"].score}")

    Process.sleep(1000)
    GenServer.cast(self(), :increment)

    accounts =
      Enum.into(accounts, %{}, fn {k, v} ->
        {k, %{v | score: v.score + 1}}
      end)

    {:noreply, accounts}
  end
end
```

`AccountManager` サーバーが保持する状態の初期値は、2 個の `Account` 構造体を値として持つマップです。

```elixir
%{
  alice: %Account{name: "Alice", score: 0},
  bob: %Account{name: "Bob", score: 0}
}
```

関数 `handle_cast/2` に対して 1 秒おきに `:increment` メッセージを送ることにより、2 個の `Account` 構造体の `score` フィールドの値が 1 ずつ増加していきます。

# AccountManager サーバーをスーパーバイザーに登録する

`lib/anemone/application.ex` を次のように書き換えてください。

```diff elixir:lib/anemone/application.ex (10-14)
      children = [
        # Starts a worker by calling: Anemone.Worker.start_link(arg)
        # {Anemone.Worker, arg}
-       Counter
+       AccountManager
      ]
```

`AccountManager` サーバーをスーパーバイザーに登録しています。

# Anemone アプリを起動する

次のコマンドを実行して Anemone アプリを起動してください。

```bash
mix run --no-halt
```

ターミナル上には次のように出力されるはずです。

```
Compiling 2 files (.ex)
alice: 0, bob: 0
alice: 1, bob: 1
alice: 2, bob: 2
alice: 3, bob: 3
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

構造体 `Account` に `stage` フィールドを追加します。

```diff elixir:lib/anemone/account.ex
  defmodule Account do
-   defstruct name: nil, score: 0
+   defstruct name: nil, score: 0, stage: 0
  end
```

# AccountManager モジュールを書き換える

`AccountManager` モジュールのソースコードを次のように書き換えてください。

```diff elixir:lib/anemone/account_manager.ex
  defmodule AccountManager do
    use GenServer
-   @vsn 1
+   @vsn 2
+   @initial_stages %{"alice" => 0, "bob" => 1}

    def start_link(_) do
      GenServer.start_link(__MODULE__, %{}, name: :account_manager)
    end

    @impl GenServer
    def init(accounts) do
      GenServer.cast(self(), :increment)

      accounts =
        accounts
-       |> Map.put("alice", %Account{name: "Alice"})
-       |> Map.put("bob", %Account{name: "Bob"})
+       |> Map.put("alice", %Account{name: "Alice", stage: @initial_stages["alice"]})
+       |> Map.put("bob", %Account{name: "Bob", stage: @initial_stages["bob"]})

      {:ok, accounts}
    end

    @impl GenServer
    def handle_cast(:increment, accounts) do
      IO.puts("alice: #{accounts["alice"].score}, bob: #{accounts["bob"].score}")

      Process.sleep(1000)
      GenServer.cast(self(), :increment)

      accounts =
        Enum.into(accounts, %{}, fn {k, v} ->
-          {k, %{v | score: v.score + 1}}
+          {k, %{v | score: v.score + v.stage + 1}}
        end)

      {:noreply, accounts}
    end

+   @impl GenServer
+   def code_change(1, accounts, _extra) do
+     accounts =
+       Enum.into(accounts, %{}, fn {k, v} ->
+         {k, Map.put(v, :stage, @initial_stages[k])}
+       end)
+
+     {:ok, accounts}
+   end
  end
```

モジュール属性（定数） `@initial_stages` を利用して、`Account` 構造体の `stage` フィールドに初期値をセットしています。

また、毎秒行われる `score` フィールドの更新で使用される計算式が `v.score + 1` から `v.score + v.stage + 1` に変更されています。この結果、`"bob"` という名前を持つ `Account` 構造体については、毎秒 2 ずつ `score` フィールドの値が増えていきます。

# ホットコードスワッピングを実施する

次のコマンドを実行して、Anemone アプリのリリースを更新します。

```bash
MIX_ENV=prod mix release --overwrite
```

起動中の Anemone アプリに IEx で接続します。

```bash
_build/prod/rel/anemone/bin/anemone remote
```

IEx 上で次の 5 つの式を順に評価してください。

```
:sys.suspend(:account_manager)
:code.purge(AccountManager)
:code.load_file(AccountManager)
:sys.change_code(:account_manager, AccountManager, 1, nil)
:sys.resume(:account_manager)
```

`Account` モジュールのコードも変更されていますが、これに関しては関数 `:code.purge/1` と `:code.load_file/1` を呼び出していません。この点については次節で扱います。

Anemone アプリを一時停止したときにターミナル上に次のように表示されていたとします。

```
...
alice: 90, bob: 90
alice: 91, bob: 91
alice: 92, bob: 92
```

このとき、Anemone アプリの稼働を再開するとターミナル上に次のように表示されていきます。

```
alice: 93, bob: 94
alice: 94, bob: 96
alice: 95, bob: 98
```

ホットコードスワッピングに成功しました。

# 構造体モジュールのコードはいつ更新されるのか

前節でホットコードスワッピングを行ったとき、`AccountManager` モジュールに関しては関数 `:code.purge/1` と `:code.load_file/1` を呼び出しましたが、`Account` モジュールに関しては何もしませんでした。しかし、ホットコードスワッピングは成功しました。

関数 `AccountManager.code_change/3` 内に `dbg %Account{}` を埋め込んでみると `%Account{name: nil, score: 0, stage: 0}` のように出力されます。詳しい仕組みはわかりませんが、新しい `AccountManager` モジュールは新しい `Account` モジュールを参照しているのです。

他方、IEx 上で式 `%Account{}` を評価すると次のように出力されます。

```elixir
%Account{name: nil, score: 0}
```

IEx のプロセスでは古い `Account` モジュールを参照しています。IEx 上で次の 2 つの式を順に評価してください。

```
:code.purge(Account)
:code.load_file(Account)
```

そして、IEx 上で式 `%Account{}` を評価し直すと次のように出力されます。

```elixir
%Account{name: nil, score: 0, stage: 0}
```

# AccountManager.code_change/3 の解説

関数 `AccountManager.code_change/3` のコードをご覧ください。

```elixir:lib/account_manager.ex (38-46)
  def code_change(1, accounts, _extra) do
    accounts =
      Enum.into(accounts, %{}, fn {k, v} ->
        {k, Map.put(v, :stage, @initial_stages[k])}
      end)

    {:ok, accounts}
  end
```

`AccountManager` サーバーが状態として保持しているマップ `accounts` の各値を作り変えています。各値は `Account` 構造体です。その `stage` フィールドに初期値をセットしています。

41 行目は次のように書けそうです。

```elixir
        {k, %{v | stage: @initial_stages[k]}}
```

しかし、この式は例外を発生させます。なぜなら `accounts` には古い `Account` モジュールによって作られた構造体を値とするマップがセットされているからです。

Elixir の構造体は、仮想マシン BEAM の観点からは単なるマップに過ぎません。`AccountManager` サーバーがバージョン 1 の時に作られた `Account` 構造体は、BEAM 上では次のようなマップとして扱われます。

```elixir
%{score: 0, name: "Alice", __struct__: Account}
```

変数 `v` にこのマップがセットされている状態で、式 `%{v | stage: 0}` を評価するとエラーになります。

# まとめ

本稿では GenServer プロセスのモジュールとその中で参照されている構造体モジュールが同時に更新された場合に、ホットコードスワッピングがどのように行われるかを見てきました。

構造体を状態として持つ GenServer プロセスのホットコードスワッピングは少し複雑です。構造体の定義が変更された場合には、新たな定義に合うように構造体を加工する必要があるからです。

[次回](https://zenn.dev/tkrd/articles/elixir-hot-code-swapping-primer-3)は、同じ構造体モジュールを参照する 2 個の GenServer プロセスが稼働しているときに、ホットコードスワッピングを行う方法について検討したいと思います。
