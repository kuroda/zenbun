---
title: Elixir で M5Stack CoreMP135 の LCD バックライトの明るさを調整する
published: true
type: tech
emoji: 🫐
topics: ["elixir", "m5stack"]
---

# 本稿について

本稿では小型 Linux PC である M5Stack CoreMP135（以下、「CoreMP135」と呼ぶ）の LCD バックライトを Elixir で調整する方法について解説します。

拙稿 [Elixir を M5Stack CoreMP135 上で動かす](https://zenn.dev/tkrd/articles/elixir-on-m5stack-core-mp135) の内容に沿って Elixir を CoreMP135 にインストールしてあることが本稿の前提条件です。

# CoreMP135 の LCD バックライトの明るさを調整する仕組み

nnn さんの Qiita 記事 [CoreMP135のLCDの明るさ調整する](https://qiita.com/nnn112358/items/e5fde681a95c6b59afeb) によれば、電源管理チップ AXP2101 を制御することで CoreMP135 の LCD バックライトの明るさを調整できます。

AXP2101 との通信は `i2c-0` というラベルを持つ I2C バス経由で行います。同記事によれば、AXP2101 のアドレスは `0x34` であり、AXP2101 の `0x99` というアドレスを持つレジスタに対して `0x00` から `0x1e` までの値を書き込むことで、LCD バックライトに供給されるで電圧が変化し、明るさが変化します。

# Elixir スクリプト

次に示すのは、私が試行錯誤の末に完成させた Elixir スクリプト `adjust_backlight.exs` です。

```elixir adjust_backlight.exs
Mix.install([
  {:circuits_i2c, "~> 2.0.5"}
])

alias Circuits.I2C

{:ok, bus} = I2C.open("i2c-0")

for value <- 0x14..0x1e do
  I2C.write(bus, 0x34, <<0x99, value>>)
  :timer.sleep(1000)
end

I2C.close(bus)
```

このスクリプトを CoreMP135 内の適当なディレクトリにおいて `elixir adjust_backlight.exs` コマンドで実行すると、LCD バックライトが最も暗い状態からだんだんと明るくなっていきます。

# ソースコードの解説

[Circuits.I2C](https://hexdocs.pm/circuits_i2c/Circuits.I2C.html) は、I2C 通信を行うための Elixir ライブラリです。

関数 `I2C.open/1` はバス名（I2C バスのラベル）を引数に取り、`:ok` と構造体 `Circuits.I2C.Bus` の組を返します。

関数 `I2C.write/3` は構造体 `Circuits.I2C.Bus`、アドレス、送信するデータを引数に取り、I2C バス経由でデータを送信します。送信するデータは 2 バイトのバイナリデータです。第 1 バイトは、レジスタのアドレスである `0x99`、第 2 バイトがレジスタに書き込む値です。

Elixir ではバイト列をバイナリと呼びます。各バイトの値をコンマ区切りで並べ、記号 `<<` と `>>` で囲むとバイナリを作れます。

`:timer.sleep(1000)` により 1 秒間隔で次第にバックライトを明るくしています。実際に試したところ、`0x14` 未満では LCD バックライトが消えてしまいました。

関数 `I2C.close/1` は構造体 `Circuits.I2C.Bus` を引数に取り、I2C 通信を切断します。

# 参考資料

* https://qiita.com/nnn112358/items/e5fde681a95c6b59afeb
* https://qiita.com/myasu/items/a4d033b5034cc3fb97c0
* https://qiita.com/kikuyuta/items/e200a6208013f38333de
